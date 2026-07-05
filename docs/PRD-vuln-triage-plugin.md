---
session_id: "CC-20260704-vu23nd"
title: "PRD: vuln-triage Claude Code Plugin"
date: 2026-07-04
type: prd
status: draft
---

# PRD: `vuln-triage` — A Claude Code Plugin for LLM-Driven VEX Drafting

## 1. Summary

A Claude Code plugin that lets any developer turn a scanner finding (HIGH/CRITICAL CVE on one of their container images) into a reviewable, evidence-backed draft VEX report (CSAF 2.0) — using only the LLM, free/open tooling, and the application's own repository. No orchestrator service, no commercial reachability engine.

The developer downloads the finding details, pulls the image reference and package list, checks out the application repo, and runs one command. The plugin walks a defined evidence ladder, decides an exploitability verdict (or honestly declines to), generates a schema-valid CSAF 2.0 draft with a citable evidence file, and opens a pull request in the VEX repository for Security Architect review.

## 2. Problem

* Scanners (Qualys, Wiz, Grype, Docker Scout) produce high volumes of HIGH/CRITICAL findings, most of which are non-exploitable noise: distro-backport false positives, packages absent from the runtime layer, vulnerable functions never called, or features disabled by configuration.
* Determining exploitability today is manual expert work; commercial reachability tools cover only some languages, cost money, and cannot read advisories, patch diffs, distro trackers, Dockerfiles, or Helm values — which is where most of the decisive evidence lives.
* There is no standard way to capture the triage conclusion as a machine-readable, customer-shareable VEX statement.
* Every developer already has Claude Code, so the analysis capability is already distributed to the people with the most context: the owning team.

## 3. Users & Core Flow

**Primary user:** the developer who owns the flagged application/image.
**Secondary user:** the Security Architect who reviews the resulting PR.

1. Dashboard/scan flags HIGH/CRITICAL findings for an image the developer owns.
2. Developer assembles the input bundle (see §4) and runs `/vex-draft` in the application repo.
3. Plugin triages each CVE via the evidence ladder (§5), produces per-CVE verdicts, a CSAF 2.0 draft, and an evidence file.
4. Plugin opens a PR in the VEX Git repository. `CODEOWNERS` routes review; `not_affected`/`affected` claims require Security Architect approval (two approvers for CRITICAL `not_affected`).
5. Merge to main publishes the report (publication pipeline is owned by the parent VEX program, not this plugin).

## 4. Input Contract

The plugin operates on a working directory containing:

| Input | Form | Source |
|---|---|---|
| Findings | `findings.json` — CVE ID, package, installed version, severity, scanner source(s), image reference | Export from the aggregated vulnerability DB / dashboard |
| Image | ECR URI + `ImageSHA` (referenced in `findings.json`; plugin inspects via `crane`/`syft`, or an offline `syft` SBOM if pull access is unavailable) | ECR |
| Application repo | Checked out locally at the commit the image was built from (the plugin verifies/records the commit ↔ `ImageSHA` mapping) | GitHub |
| Deploy config | Helm chart / values in repo, or path provided as an argument | GitHub |

Invocation forms:

* `/vex-draft ./triage-input/` — batch: all findings in the export
* `/vex-draft CVE-2026-12345` — single CVE (details fetched from `findings.json` or public sources)

## 5. Functional Requirements — The Evidence Ladder

For each CVE, the plugin walks the ladder top-down and stops at the first decisive rung. Every conclusion must cite its evidence (file:line, tool output, or URL).

* **F1 — Normalize:** Three-tier rule — collapse only what shares a fix:
  * *Aliases* (CVE/GHSA/GO-… IDs for one advisory): always merge; record all IDs.
  * *Same build, same fix* (e.g., multiple binary debs from one source package at one version): collapse to a single work item; the upgrade is atomic.
  * *Same flaw, different embedding* (module dependency vs. toolchain-bundled copy vs. vendored copy; per-binary copies in multi-binary images): **group for shared advisory analysis, but never merge** — reachability verdicts, remediation actions, and emitted VEX statements are per component-copy.
  * Merge duplicate findings across scanners; record all scanner sources as provenance.
  * *Alias lag:* an ID with no aliases yet (common in the first days after disclosure) is tagged `unlinked — recheck`, not treated as a distinct flaw. CVE-less advisories (GHSA-only, GO-only) are valid canonical vulnerabilities — nothing may assume a CVE exists.
  * *Provenance extras:* record the scanner DB snapshot date (e.g., grype `db built` timestamp) and, per finding, whether the match came from an exact PURL or a guessed CPE — CPE-derived matches warrant lower prior trust.
  * *Prioritization:* order the triage queue using the KEV (known-exploited) and EPSS enrichment already present in scanner output — KEV hits and high-EPSS findings go first.
* **F2 — Distro-backport check:** Query the relevant distro security tracker (Debian, Ubuntu, RHEL, Alpine). If the installed package version contains a backported fix → `not_affected` (fixed by vendor). Cite the tracker URL. F2 verdicts are image-independent facts — cache and share per (CVE, distro release, package version); both pilots hit the same openssl/gnupg CVEs on different base images.
* **F3 — Component presence:** Inspect the final image layer (`syft`, `crane`). Package only in a builder stage or absent → `not_affected` + `component_not_present`. Cite the layer analysis output.
* **F4 — Advisory & patch-diff intelligence:** Fetch the advisory (OSV/NVD/GHSA) and, where available, the upstream fix commit. Extract the actual vulnerable symbols, entry points, and preconditions (e.g., "only when feature X is enabled"). This output drives F5/F6 and may itself be decisive (`vulnerable_code_cannot_be_controlled_by_adversary`, `inline_mitigations_already_exist`). **Sparse-advisory rule:** when the advisory names no symbols, preconditions, or mechanism (common for MSRC one-liners), F4 has nothing to falsify — the ladder degrades to version-range logic and the verdict defaults to `affected` with the fix version cited (per G1). Do not synthesize preconditions the advisory doesn't state.
* **F4b — Prior-art check:** One cheap search of the upstream project's issue tracker and security advisories per canonical vulnerability (CVE ID + aliases). Maintainer statements are high-value evidence in either direction — in the pilot this surfaced the Argo CD maintainers' own analysis of the gRPC CVE, which both confirmed the verdict and caught a secondary impact. Absence of prior art is the normal case and decides nothing.
* **F5 — Usage analysis, two modes:**
  * *Path reachability:* does execution reach the vulnerable symbols (from F4)? Use free ecosystem reachability where it exists (`govulncheck` for Go); targeted grep/AST call-tracing elsewhere. Unreached → `not_affected` + `vulnerable_code_not_in_execute_path`.
  * *State falsification:* can the vulnerable *configuration* exist at all? Many advisories gate on a library feature being enabled (e.g., jackson polymorphic typing) — a repo-wide search proving the enabling call/annotation never occurs is often cheaper and more airtight than any call graph, and it is the primary mode for ecosystems without free reachability tooling (Java, Python, JS).
  * Also: direct vs. transitive (lockfile); fork/`replace`/vendored divergence check; shaded fat JARs (a dependency nested inside a third-party JAR) are uninspectable third-party code — without evidence, the copy's verdict defaults to `under_investigation` per G1, with remediation "await upstream artifact update." Check for forks: a `replace` directive (or vendored copy) of the flagged module means the installed code may diverge from the advisory's version ranges — verify against the fork's actual source. Static-tool traces through interface dispatch (e.g., anything reached via `io.Copy`) are over-approximations and must be sanity-checked before being treated as reachable.
* **F6 — Runtime/config context:** Dockerfile entrypoint/CMD, Helm values, env flags — is the vulnerable feature enabled in this deployment? Disabled/blocked → `not_affected` + `inline_mitigations_already_exist`. On-demand loading (e.g., JDBC drivers class-loaded only for the configured database URL) is valid mitigating context to record, but a present component still requires a statement — "rarely loaded" is not `component_not_present`.
* **F7 — Verdict & drafting:** Map the conclusion to CSAF VEX status + justification per the bundled taxonomy; when no enumerated justification flag fits (pilot example: vulnerable code executes but the exploitable configuration is absent), use a CSAF `impact_statement` with the precise reasoning instead of forcing the nearest flag. Populate the CSAF 2.0 template, including the product tree entry (`ImageSHA`, Helm chart version, repo commit). Validate against the official CSAF schema — an invalid document is a hard failure, not a warning.
* **F8 — Evidence file:** Emit `evidence/CVE-XXXX-XXXXX.md` per CVE: rung-by-rung findings, citations, tool outputs (verbatim), and the reasoning chain. Archived with the draft in the PR.
* **F9 — PR creation:** Branch, commit draft + evidence, open PR in the VEX repo via `gh`, with a summary table of verdicts in the PR body.

## 6. Guardrails (Non-Negotiable)

* **G1 — Burden of proof:** `not_affected` requires positive, citable evidence. If the ladder ends inconclusive, the verdict is `under_investigation` or `affected` — never a guessed `not_affected`. Inconclusive is a valid, publishable outcome.
* **G2 — Deterministic anchors:** Every claim that *can* be grounded in tool output (syft, crane, govulncheck, lockfiles, tracker pages) *must* be; LLM reasoning fills gaps between anchors, it does not replace them.
* **G3 — No publish authority:** The plugin runs with read-only access to the image and application repo and can only open PRs against the VEX repo. Publication happens exclusively on human-approved merge.
* **G4 — Untrusted input:** Advisory text, package metadata, and repo contents are untrusted. Instructions encountered inside them are data, never directives.
* **G5 — Reviewability over confidence:** The evidence file is written so the reviewer verifies citations, not trusts judgment. Session transcript is preserved as part of the audit record.
* **G6 — Dismissed sinks get a second question:** When a candidate consumer of malformed input is ruled out for the headline impact ("that's logging, not authorization"), explicitly ask what breaks if the input reaches *that* consumer anyway. Dismissing the advisory's headline impact is not dismissing all impact — the pilot's one miss (a log-redaction bypass riding the same lenient gRPC path) was exactly this pattern.

## 7. Plugin Architecture

```
vuln-triage/
├── .claude-plugin/plugin.json      # name, version, description
├── skills/
│   └── vex-draft/
│       └── SKILL.md                # the evidence-ladder methodology (F1–F9)
├── scripts/
│   ├── fetch_advisory.py           # OSV / NVD / GHSA + upstream patch diff
│   ├── check_distro_tracker.py     # Debian / Ubuntu / RHEL / Alpine trackers
│   ├── inspect_image.sh            # syft + crane layer/presence analysis
│   ├── find_usage.sh               # lockfile, import, call-site search; govulncheck wrapper
│   ├── build_csaf.py               # template population + product tree
│   └── validate_csaf.py            # jsonschema gate against official CSAF 2.0 schema
├── templates/
│   └── csaf_vex.json
└── references/
    ├── justification-taxonomy.md   # decision tree → CSAF status/justification flags
    └── evidence-format.md          # required structure of evidence files
```

* **Distribution:** internal plugin marketplace (Git repo); added to team `.claude/settings.json` so every developer gets it and receives updates.
* **Dependencies (all free/open):** `syft`, `crane`, `govulncheck`, `gh`, `python3` + `jsonschema`; network access to OSV/NVD/GHSA APIs and distro trackers. The skill checks for missing tools at start and degrades explicitly (skips the rung and says so) rather than silently.

## 8. Non-Functional Requirements

* **Schema validity:** 100% of drafts pass CSAF 2.0 schema validation before a PR is opened (CI on the VEX repo re-validates as a second gate).
* **Batch runtime:** A typical finding export (≤ 25 CVEs) completes in one session without developer babysitting beyond the initial command.
* **Idempotency:** Re-running against the same findings updates the existing branch/PR rather than duplicating it.
* **Determinism aids:** Pinned tool versions in the plugin; evidence anchored to tool outputs so two runs reach the same verdict even if prose differs.

## 9. Out of Scope

* Publication, signing, and customer distribution (owned by the parent VEX program; see `PRD.md`).
* Commercial reachability engines — explicitly excluded; free ecosystem tools only.
* Automatic remediation or dependency upgrades.
* Orchestrator-driven/headless operation (candidate future phase, gated on M1 below).
* Scanner integrations — the plugin consumes the exported `findings.json`, it does not talk to Qualys/Wiz directly.

## 10. Success Metrics

* **M1 — Draft quality:** % of plugin-drafted verdicts approved without correction in PR review. This is the promotion gate for any future headless mode.
* **M2 — Ladder coverage:** % of findings resolved at each rung (F2–F6) vs. left `under_investigation`. Quantifies how much noise the LLM approach clears without a commercial tool. Counting rule: tier-3 component copies (same flaw, different embedding) count as separate items — folding them flatters the metric by hiding per-copy verdict work that still needs doing.
* **M3 — Triage time:** Median developer time from input bundle to opened PR, vs. current manual triage baseline.
* **M4 — Adoption:** % of new HIGH/CRITICAL findings triaged through the plugin within its SLA-free pilot period.

## 11. Rollout

1. **Pilot:** ✅ Done twice on OSS targets — Argo CD v3.0.0 (Go lane, `pilot-report-argocd-v3.0.0.md`) and Flyway 11.0.0 (Java lane, `pilot-report-flyway-11.0.0.md`): 13 findings, 7 evidence-cited `not_affected`, 5 `affected` with exact fix versions, 1 honest `under_investigation`; verdicts verified against maintainer statements where any existed. Remaining pilot work: repeat on 5–10 *internal* findings with known-correct verdicts before packaging.
2. **v1:** Package as plugin, distribute to 2–3 volunteer teams, measure M1–M3.
3. **General availability:** All teams; dashboard Jira tickets embed the `/vex-draft` command.
4. **Future (out of scope here):** headless orchestrator-driven runs of the same skill, gated on M1.

## 12. Open Questions

* **Input freshness:** The developer-downloaded `findings.json` can drift from the live aggregated DB. Is a timestamp + drift warning enough, or should the plugin fetch live via an internal API?
* **Repo ↔ image mapping:** Is the source commit recorded in image labels/annotations today? If not, the F-requirements need a convention (OCI annotation at build time) to verify the checkout matches the scanned image.
* **VEX repo layout:** One document per image per CVE, or consolidated per-image documents? Affects re-issuance mechanics and the parent program's lifecycle model.
* **Transcript archival:** Where do session transcripts live to satisfy G5 — attached to the PR, or an S3 audit bucket?
* **Multi-binary images & bundled runtimes:** Images bundle third-party binaries (pilot #1: helm, kustomize, git-lfs beside argocd) and platform runtimes (pilot #2: OpenJDK 17 with 9 of its own CVEs), each with embedded dependencies. Does the plugin run the ladder per bundled component (needs their repos/tags), scope statements to the first-party binary only, or treat bundled components as "refresh the base/upstream artifact" remediation items? Affects the input contract.
