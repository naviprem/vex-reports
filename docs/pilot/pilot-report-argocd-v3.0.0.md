---
session_id: "CC-20260704-vu23nd"
title: "Pilot: LLM-driven VEX triage of Argo CD v3.0.0"
date: 2026-07-04
type: pilot-report
status: complete
---

# Pilot Report: LLM-Driven VEX Triage — Argo CD v3.0.0

**Thesis under test:** an LLM agent + free tooling (no commercial reachability engine) can produce defensible, evidence-cited VEX verdicts for real HIGH/CRITICAL scanner findings.

**Target:** `quay.io/argoproj/argocd:v3.0.0` (Ubuntu 24.04 "noble" base, Go application), source at tag `v3.0.0`.
**Toolchain used (all free):** grype (registry scan, no Docker daemon), govulncheck (symbol-level reachability), Ubuntu Security API, OSV.dev API, grep/code reading. Setup time from zero: ~5 minutes.

## Scanner baseline (the noise problem, quantified)

* grype reported **684 findings** on the image; **151 HIGH/CRITICAL rows**, deduplicating to ~40 unique CVE×package pairs (rung F1 alone removes ~75% of rows — e.g., each Go stdlib advisory repeats across the four Go toolchain versions baked into the image's various binaries).
* govulncheck reduced the Go-module findings to **49 advisories with statically reachable symbols** — everything else is pruned with soundness, for free.

## Verdicts (6 findings walked through the ladder)

| Finding | Package (installed) | Severity | Decisive rung | Verdict |
|---|---|---|---|---|
| CVE-2026-45447 | openssl `3.0.13-0ubuntu3.5` (deb) | High | F2 tracker | **affected** — fix exists |
| CVE-2025-48384 | git `1:2.43.0-1ubuntu7.2` (deb) | High | F2 + F6 | **affected** — priority |
| GHSA-p77j-4mvh-x3m3 / CVE-2026-33186 | grpc `v1.71.0` | Critical | F4 + F5 + code read | **not_affected** |
| GO-2026-5019 / CVE-2026-39831 | x/crypto `v0.36.0` | Critical | F4 + F5 | **not_affected** |
| GO-2026-5020 / CVE-2026-39834 | x/crypto `v0.36.0` | Critical | F4 + F5 | **not_affected** |
| GO-2025-3525 / CVE-2025-29786 | expr `v1.16.9` | High | F5 + code read | **not_affected** |

### 1. CVE-2026-45447 — openssl (deb) → `affected`

* **F2 (Ubuntu Security API):** fix **released** for noble in `3.0.13-0ubuntu3.11`; image carries `3.0.13-0ubuntu3.5` → behind the fix. Not a backport false positive — the tracker worked in the *confirming* direction and pinpointed the exact remediation version.
* **Remediation:** rebuild on current base / consume a newer argocd tag.

### 2. CVE-2025-48384 — git (deb) → `affected` (priority)

* **F2:** fix released for noble in `1:2.43.0-1ubuntu7.3`; image carries `...7.2` → behind.
* **F6 (context):** this CVE class (config/submodule handling) is aggravated here — argocd's repo-server invokes the `git` CLI against **user-configured repositories, including submodules**, so the vulnerable surface faces semi-untrusted input. Flagged for expedited remediation, not just routine base-image refresh.

### 3. gRPC `:path` authorization bypass (Critical) → `not_affected`

* **F4 (advisory):** exploit requires **both** (a) authorization interceptors keyed on the raw `:path`/`FullMethod`, and (b) a policy of deny-rules-on-canonical-paths with a fallback allow.
* **F5 (govulncheck):** vulnerable routing code *is* reachable — argocd runs gRPC servers (`server/server.go:1607`, `cmpserver/server.go:100`). Reachability alone would say "affected."
* **Code read (the LLM layer):** argocd's `Authenticate` interceptor (`server/server.go:1479`) is **token-based and path-independent**; downstream RBAC operates on resource/action claims, not the HTTP/2 path. The only `FullMethod` matches in the server (`server/server.go:943,957`) gate *log redaction*, not authorization. Precondition (a) is absent.
* **Verdict:** `not_affected`, with a CSAF **impact_statement** (no taxonomy flag fits cleanly — the code executes, but the exploitable configuration does not exist). Upgrade still recommended as hygiene.

### 4. x/crypto/ssh FIDO/U2F touch bypass (Critical) → `not_affected`

* **F4:** vulnerability affects SSH **servers** verifying `sk-*` security-key user authentication (User Presence flag not checked in `Verify()`).
* **F5 (govulncheck):** reachable only via `ssh.CertChecker.CheckHostKey` / `ssh.NewClientConn` from `util/git/workaround.go:25` — argocd acts exclusively as an SSH **client** to git servers (`util/git/ssh.go`); it never authenticates users' security keys.
* **Verdict:** `not_affected` + `vulnerable_code_cannot_be_controlled_by_adversary`.

### 5. x/crypto/ssh infinite loop on >4GB channel writes (Critical) → `not_affected`

* **F4:** trigger is a **single `Write` call larger than 4 GiB** on an SSH channel.
* **F5:** argocd's SSH writes go through go-git pack negotiation (pkt-line sized) and `io.Copy` (32 KiB buffer → each `Write` ≤ 32 KiB). The govulncheck trace `http.Client.Do → io.Copy → ssh.channel.Write` is an interface-dispatch over-approximation. No code path can issue a multi-GB single write, and an adversary cannot induce one.
* **Verdict:** `not_affected` + `vulnerable_code_cannot_be_controlled_by_adversary`.

### 6. expr parser memory exhaustion (High) → `not_affected`

* **F5:** single non-test use: `server/deeplinks/deeplinks.go:88` (`expr.Eval(*link.Condition, obj)`).
* **Code read:** the parsed expression string (`link.Condition`) originates from `SettingsManager.GetDeepLinks` (`util/settings/settings.go:879`) reading the `argocd-cm` ConfigMap (`application.links` / `project.links` / `resource.links`) — **operator-controlled configuration**, not end-user input. The "unbounded input" precondition requires the attacker to author the expression itself.
* **Verdict:** `not_affected` + `vulnerable_code_cannot_be_controlled_by_adversary` (caveat recorded for deployments where ConfigMap write access is granted to semi-trusted tenants).

## Sample draft VEX statement (as the plugin would emit)

```json
{
  "vulnerability": { "cve": "CVE-2025-29786" },
  "product_status": { "known_not_affected": ["quay.io/argoproj/argocd@sha256:<v3.0.0-digest>"] },
  "flags": [{ "label": "vulnerable_code_cannot_be_controlled_by_adversary" }],
  "notes": [{
    "category": "description",
    "text": "expr v1.16.9 parser memory exhaustion requires attacker-supplied expression strings. In Argo CD, expressions reach expr.Eval only via deep-link Conditions (server/deeplinks/deeplinks.go:88) sourced from the operator-controlled argocd-cm ConfigMap (util/settings/settings.go:879). End users cannot supply expression input."
  }]
}
```

## What the pilot demonstrates

1. **Coverage:** 4 of 6 findings — including **all three Criticals** — resolved to evidence-backed `not_affected`; the 2 genuine `affected` verdicts came with exact fix versions and a priority signal. Zero `under_investigation` residue in this sample.
2. **The LLM layer is load-bearing exactly where predicted:** every `not_affected` verdict required reading advisory preconditions and application code (trust boundaries, client-vs-server role, write sizes) that no static tool evaluates. Conversely, reachability alone would have called #3–#5 "affected" — precondition analysis is what converts noise into signal.
3. **Free tooling sufficed:** registry scanning without a Docker daemon, symbol-level reachability (govulncheck), and authoritative distro data (Ubuntu Security API) — the plugin's §7 dependency list is validated.
4. **Honesty pressure-tested:** the deb findings were *expected* to be backport false positives; the tracker showed the image was simply behind the fixes, and the verdicts followed the evidence, not the expectation.

## Verification against owner "actuals" (added 2026-07-04, same day)

Verdicts were cross-checked against statements from the actual owners at each tier: Ubuntu Security (deb packages), upstream module maintainers (advisory preconditions), and the Argo CD maintainers (application-level exploitability).

| Finding | Pilot verdict | Owner actual | Match |
|---|---|---|---|
| gRPC `:path` bypass | `not_affected` (no path-based authz) | Argo CD maintainer (argoproj/argo-cd#26932): "Argo CD's authentication and authorization processes do not rely on checking the gRPC method name. Therefore, Argo CD was not vulnerable to any authentication or authorization bypass attacks." Same reasoning, same code cited. | ✅ confirmed — with a nuance we missed (below) |
| expr memory exhaustion | `not_affected` (operator-controlled input) | No exploitability claim by maintainers; treated as scanner-driven hygiene — bumped to v1.17.0 (#22651), users pointed to the project's "A word about security scanners" policy (#23249). | ✅ consistent |
| x/crypto FIDO + >4GB write | `not_affected` ×2 | **No Argo CD maintainer statement exists** (zero tracker hits for either CVE). Only owner evidence is the upstream golang advisory preconditions — which is what the pilot used. | ⚪ unverifiable at app tier — this is the normal case, and precisely the gap VEX exists to fill |
| openssl / git (deb) | `affected`, behind fix | Owner of record is Ubuntu Security; the tracker *was* the evidence (fixes released in `3.0.13-0ubuntu3.11` / `1:2.43.0-1ubuntu7.3`). | ✅ by construction |

**The nuance we missed (gRPC):** the maintainers' analysis (#26932) went one level deeper. The `sensitiveMethods[c.FullMethod()]` log-redaction gate — which the pilot correctly identified at `server/server.go:943,957` and correctly classified as "not authorization" — was itself bypassable via the same lenient `:path`, causing **sensitive payloads to be logged unredacted** for exactly one streaming method (`ApplicationService/GetManifestsWithFiles`). Argo CD shipped the advisory's recommended path-validation interceptor as a mitigation (#26982/#26983) and bumped grpc to 1.79.3 in release-3.3. So the pilot's verdict on the Critical question (authz bypass) was right, but a secondary lower-severity impact (information disclosure into logs) rode the same vulnerable behavior.

**Lessons for the SKILL.md:**
1. When a candidate sink is dismissed ("that's logging, not authz"), ask the follow-up: *what breaks if the malformed input reaches this non-authz consumer?* Dismissal of the headline impact is not dismissal of all impact.
2. Add an explicit **prior-art rung** to the ladder (cheap: one issue-tracker/advisory search per CVE ID + aliases). In this pilot it produced maintainer confirmation for 2 of 4 Go findings in seconds, and on the gRPC case it surfaced analysis deeper than ours.
3. The two x/crypto CVEs show why the plugin matters: for most dependency CVEs, **no application-owner statement will ever exist** — the VEX document produced by this process *is* the owner statement your customers get.

## Caveats & follow-ups

* The image contains **other Go binaries** (helm, kustomize, git-lfs — the source of the duplicated stdlib findings). Repo-level analysis covers the argocd binary; a full triage run needs the same ladder per bundled binary, or `component_not_present`-style reasoning per binary.
* Wall-clock for 6 findings incl. environment setup: ~20 minutes. Marginal per-CVE cost after setup: ~2–3 minutes, dominated by evidence reading — consistent with the M3 metric ambition.
* The gRPC case shows the justification taxonomy needs the CSAF **impact_statement** escape hatch — worth adding to `references/justification-taxonomy.md` in the plugin design.

**Artifacts:** grype JSON, govulncheck output, OSV/Ubuntu API responses, and the cloned repo are in the session scratchpad (`pilot/`).
