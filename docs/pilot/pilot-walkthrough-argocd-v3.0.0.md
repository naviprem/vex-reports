---
session_id: "CC-20260704-vu23nd"
title: "Pilot Walkthrough: LLM-driven VEX triage of Argo CD v3.0.0 (detailed)"
date: 2026-07-04
type: pilot-walkthrough
status: complete
---

# Pilot Walkthrough — LLM-Driven VEX Triage of Argo CD v3.0.0

Detailed, reproducible record of the pilot run on 2026-07-04. Companion to `pilot-report-argocd-v3.0.0.md` (results summary); this document records every command, the relevant outputs, and the reasoning chain per finding, rung by rung. It is also the raw material for the plugin's `skills/vex-draft/SKILL.md`.

## 0. Environment

| Component    | Version / State                                                           |
| ------------ | ------------------------------------------------------------------------- |
| Host         | macOS (darwin arm64), Docker daemon **not running**                       |
| grype        | 0.115.0 (installed via `brew install grype`)                              |
| syft         | 1.46.0 (`brew install syft`)                                              |
| crane        | (`brew install crane`)                                                    |
| govulncheck  | v1.5.0 (`go install golang.org/x/vuln/cmd/govulncheck@latest`), Go 1.25.4 |
| Network APIs | OSV.dev, Ubuntu Security API, quay.io registry, GitHub                    |

Setup from a machine with none of these tools: **~5 minutes**. Total pilot wall-clock including setup and scans: **~20 minutes**.

**Target:**
- Image: `quay.io/argoproj/argocd:v3.0.0` — digest `sha256:a87457ade255ec5d58857c8881398a07dede7700e6c4f44b7c27b2ea68562306`
- Base: Ubuntu 24.04 LTS ("noble")
- Source: `github.com/argoproj/argo-cd` at tag `v3.0.0` (go 1.24.1 in go.mod)

**Why this target:** very popular, containerized, Go (so the one free symbol-level reachability tool, govulncheck, applies), Ubuntu base (exercises the distro-tracker rung), and released 2025-05 — 14 months of subsequently-reported CVEs hit its pinned dependencies.

## 1. Input acquisition (plugin input contract, §4 of plugin PRD)

```bash
# Scan the image directly from the registry — no Docker daemon needed
grype registry:quay.io/argoproj/argocd:v3.0.0 -o json > grype-argocd-v3.0.0.json

# Source checkout at the exact release tag
git clone --depth 1 --branch v3.0.0 https://github.com/argoproj/argo-cd.git
```

Notes:
- `registry:` scheme worked with the daemon down — validates that the plugin does not require Docker.
- In the real plugin, `findings.json` would come from the aggregated vuln DB export; here grype plays that role.
- The repo↔image commit mapping was assumed from the tag name; a production run must verify it (open question in the plugin PRD — OCI annotation at build time).

## 2. Rung F1 — Normalize / dedupe

```bash
jq '.matches | length'   # 684
jq -r '[.matches[].vulnerability.severity] | group_by(.) | map("\(.[0]): \(length)")[]'
# Critical: 19, High: 132, Medium: 411, Low: 117, Negligible: 5
```

- **684 raw findings; 151 HIGH/CRITICAL rows → 75 unique CVE×package pairs** after dedup (`jq unique` on id+name).
- Main duplication sources: the same Go stdlib advisory reported once per Go toolchain version found in the image (`go1.22.2`, `go1.22.7`, `go1.23.5`, `go1.24.1` — the image bundles several Go binaries: argocd, helm, kustomize, git-lfs), and the same deb CVE listed per binary package built from one source (`gpg`, `gpgv`, `gpg-agent`, … all from `gnupg2`).
- Aliases observed and resolved during the run: `GHSA-p77j-4mvh-x3m3` = `CVE-2026-33186` = `GO-2026-4762`; `GHSA-93mq-9ffx-83m2` = `CVE-2025-29786` = `GO-2025-3525`.

**Pilot selection (6 findings, chosen to span both lanes and all severities):** openssl and git (deb lane), grpc + 2× x/crypto (Critical, Go lane), expr (High, Go lane). Argo CD's *own* GHSAs (fixed in later argocd versions) were excluded — those are "upgrade the product" advisories, not dependency triage.

## 3. Rung F2 — Distro-backport check (deb lane)

The Ubuntu Security API is JSON and needs no scraping:

```bash
curl -s https://ubuntu.com/security/cves/CVE-2026-45447.json |
  jq '.packages[] | select(.name=="openssl") | .statuses[] | select(.release_codename=="noble")'
```

| CVE | Package installed | Ubuntu noble status | Conclusion |
|---|---|---|---|
| CVE-2026-45447 | openssl `3.0.13-0ubuntu3.5` | **released** in `3.0.13-0ubuntu3.11` | image behind fix → **affected** |
| CVE-2025-48384 | git `1:2.43.0-1ubuntu7.2` | **released** in `1:2.43.0-1ubuntu7.3` | image behind fix → **affected** |

Two methodological points:
- Expected outcome was backport false positives (scanner flags a version string that already contains the backported fix). Actual outcome: the image genuinely lagged the fixes. **The rung is decisive either way** — it either kills the finding or names the exact remediation version.
- For CVE-2025-48384 the ladder didn't stop at F2: rung F6 context (argocd repo-server executes the `git` CLI against user-configured repositories, submodules included) upgraded it from "routine base-image refresh" to "priority remediation," since the vulnerable surface faces semi-untrusted input.

## 4. Rung F4 — Advisory & patch intelligence (Go lane)

```bash
curl -s https://api.osv.dev/v1/vulns/GHSA-p77j-4mvh-x3m3   # etc.
```

Extracted preconditions (the decisive facts, one line each):

| Advisory | Vulnerable surface | Exploit precondition |
|---|---|---|
| GHSA-p77j-4mvh-x3m3 (grpc, Critical) | HTTP/2 `:path` routing leniency | Server must use **path-based authz** (`info.FullMethod` / `grpc/authz`) with deny-rules-on-canonical-paths + fallback allow |
| GO-2026-5019 (x/crypto/ssh, Critical) | `Verify()` for `sk-*` FIDO keys skips User-Presence flag | Host must act as **SSH server** authenticating users' security keys (`PublicKeyCallback`) |
| GO-2026-5020 (x/crypto/ssh, Critical) | int overflow in channel write loop | A **single `Write` call > 4 GiB** on an SSH channel |
| GO-2025-3525 (expr, High) | parser allocates AST proportional to input | **Attacker-supplied, unbounded expression string** |

This rung is pure LLM work: the preconditions live in advisory prose. No scanner evaluates them.

## 5. Rung F5 — Reachability & usage analysis

### 5a. govulncheck (free symbol-level reachability)

```bash
cd argo-cd && govulncheck ./... > govulncheck.txt   # exit code 3 = findings exist
```

- Output: 13,511 lines, **49 advisories with reachable symbols** ("Symbol Results"); every module-level advisory without a reachable symbol is pruned — sound noise reduction, for free.
- All four pilot Go advisories appeared in Symbol Results, i.e., **statically reachable**. Reachability alone would convict all four. The traces:

```text
GO-2026-4762 (grpc)   #1 cmpserver/server.go:100: ArgoCDCMPServer.Run calls grpc.Server.Serve
                      #2 server/server.go:1607: handlerSwitcher.ServeHTTP → grpc.Server.ServeHTTP
GO-2026-5019 (ssh)    #1 util/git/workaround.go:25: newUploadPackSession → … → ssh.CertChecker.CheckHostKey
GO-2026-5020 (ssh)    #1 util/git/workaround.go:25: newUploadPackSession → … → ssh.Session.Start
                      #3 applicationset/…/http/client.go:120: http.Client.Do → io.Copy → ssh.channel.Write
GO-2025-3525 (expr)   #1 server/deeplinks/deeplinks.go:88: EvaluateDeepLinksResponse → expr.Eval → parser.ParseWithConfig
```

Trace #3 for GO-2026-5020 is a known static-analysis artifact: `io.Copy` dispatches through the `io.Writer` interface, so the call graph includes *every* `Write` implementation in the binary. An HTTP client does not write to SSH channels. Recognizing over-approximated interface-dispatch edges is itself an LLM-layer job.

### 5b. Usage location (grep)

```bash
grep -rl "expr-lang/expr" --include="*.go" . | grep -v _test
# → server/deeplinks/deeplinks.go   (single non-test use in the codebase)
grep -rl "golang.org/x/crypto/ssh" --include="*.go" . | grep -v _test
# → util/cert/cert.go, util/db/certificate.go, util/git/client.go, util/git/ssh.go  (all git-client side)
```

## 6. Rung F5/F6 — Targeted code reading (the verdict-flipping evidence)

### grpc — does the vulnerable authz pattern exist?

```bash
grep -rn "FullMethod" server/*.go util/session/*.go | grep -v _test
# server/server.go:943, 957 — both inside PayloadServerInterceptor:
#   return !sensitiveMethods[c.FullMethod()]     ← log-redaction gate, NOT authorization
```

Read `server/server.go:1479` (`ArgoCDServer.Authenticate`): authentication is **token-based and path-independent** — it reads JWT claims from gRPC metadata (`getClaims`), never consults the method path; RBAC downstream operates on resource/action claims. The exploit's required pattern (deny rules keyed on canonical paths + fallback allow) does not exist. The cmpserver (trace #1) is a localhost Unix-socket plugin server with no path-based policy either.
**Verdict: `not_affected`** — via CSAF `impact_statement` (no enumerated justification flag fits: the code executes, the exploitable *configuration* is absent).

### x/crypto FIDO (GO-2026-5019)

Traces reach the vulnerable module only through `CheckHostKey`/`NewClientConn` — argocd is an SSH **client** verifying git servers' host keys. The vulnerability's harm model (accepting security-key user-auth signatures made without physical touch) requires the SSH **server** role, which argocd never performs (`util/git/ssh.go` is client-only).
**Verdict: `not_affected` + `vulnerable_code_cannot_be_controlled_by_adversary`.**

### x/crypto >4GB write (GO-2026-5020)

go-git upload-pack negotiation writes pkt-line-sized chunks; the `io.Copy` path writes ≤ 32 KiB per `Write` (stdlib buffer size). No code path can issue a single multi-gigabyte `Write`, and no adversary input can induce one.
**Verdict: `not_affected` + `vulnerable_code_cannot_be_controlled_by_adversary`.**

### expr (GO-2025-3525)

```bash
sed -n '83,100p' server/deeplinks/deeplinks.go   # expr.Eval(*link.Condition, obj)
grep -n "DeepLinks" util/settings/settings.go
# :529 application.links  :531 project.links  :533 resource.links
# :879 SettingsManager.GetDeepLinks — reads argocd-cm ConfigMap
```

The *parsed string* (`link.Condition` — what the CVE is about) is authored by whoever writes the `argocd-cm` ConfigMap: the operator. End users trigger evaluation but cannot supply the expression.
**Verdict: `not_affected` + `vulnerable_code_cannot_be_controlled_by_adversary`** (caveat recorded: revisit in deployments granting ConfigMap write to semi-trusted tenants).

## 7. Rungs F7/F8 — Drafting & evidence

Sample emitted statement: see `pilot-report-argocd-v3.0.0.md` §"Sample draft VEX statement". Each verdict above carries its citations (file:line, tool output, API URL) — the structure the plugin's `evidence-format.md` should mandate. F9 (PR creation) was out of scope for the pilot (no VEX repo exists yet).

## 8. Findings about the method itself

1. **Ladder ordering is right.** F2 resolved both deb findings without touching code; F4 preconditions made F5/F6 targeted (grep for *specific symbols/patterns*, not open-ended review). Marginal cost ≈ 2–3 min/finding after setup.
2. **Reachability ≠ exploitability, demonstrated 4/4.** Every Go finding was govulncheck-reachable; every one resolved `not_affected` on preconditions. A pipeline that stopped at reachability would have shipped three false `affected` Criticals — the inverse failure mode of scanner noise.
3. **The taxonomy needs the `impact_statement` escape hatch** (grpc case). Action: add to `references/justification-taxonomy.md`.
4. **Multi-binary images need per-binary treatment.** The stdlib duplicate rows trace to bundled helm/kustomize/git-lfs binaries; the argocd repo analysis says nothing about them. The plugin must either run the ladder per bundled binary or scope statements to the analyzed binary.
5. **Interface-dispatch over-approximation** (io.Copy trace) is a recurring govulncheck artifact the SKILL.md should teach explicitly.
6. **Honesty check passed:** expected backport false positives turned out to be real lag; verdicts followed evidence against expectation.

## 9. Artifacts (session scratchpad, `pilot/`)

| File | Size | Content |
|---|---|---|
| `grype-argocd-v3.0.0.json` | 2.7 MB | full scanner output, 684 matches |
| `govulncheck.txt` | 2.4 MB | full reachability output, 49 Symbol Results |
| `osv-*.json` (×4) | ~11 KB | OSV advisories for the Go findings |
| `ubuntu-CVE-*.json` (×2) | ~51 KB | Ubuntu Security API responses |
| `argo-cd/` | — | shallow clone at v3.0.0 |

Note: the scratchpad is session-scoped; copy artifacts out if long-term retention is needed (in production, G5 mandates archiving them with the PR).
