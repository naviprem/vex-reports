# Target Matrix — 20–25 pilot coverage plan

Per protocol §6. Each dimension needs ≥2 targets before a rule counts as "generalized"
rather than "fit one target". ✅ = exercised by a seeded pilot; ⬜ = untested (Phase A/B fodder).

## Pilot cell assignments

| Pilot | Target | Language | Base distro | Image shape | Advisory quality | Direction | Provenance | Status |
|---|---|---|---|---|---|---|---|---|
| 1 | argocd:v3.0.0 | Go | Ubuntu noble | single binary (+ bundled go binaries) | rich GHSA/GO | mixed (2 affected / 4 not_affected) | PURL | seeded |
| 2 | flyway:11.0.0 | Java | Ubuntu jammy | fat/shaded JAR + bundled JRE + driver JARs | mixed (rich GHSA + sparse MSRC) | mixed (3 affected / 3 not_affected / 1 under_inv) | PURL | seeded |
| 3 | paperless-ngx:2.20.15 | **Python/Django** | **Debian 13** | platform runtime (CPython) + deep pip tree + bundled binaries | rich GHSA/PYSEC | mixed (8 affected / 10 not_affected) | PURL | **Phase A — adjudicated; awaiting Runner** |

digest: `sha256:6c86cad803970ea782683a8e80e7403444c5bf3cf70de63b4d3c8e87500db92f` · repo_commit: `05e48b2`

**Adjudication result (blind ground truth written before any Runner run):** 18 graded entries — Python lane 12 (4 affected inc. pdfminer RCE + granian unauth-DoS; 8 not_affected via mode-B falsification), deb lane 6 (Debian F2 tracker: openssl/imagemagick fixed-behind, libheif no-fix, expat no-dsa → affected; perl postponed + glib no-dsa → not_affected via reachability). Deferred tier-3 lanes (gosu Go-stdlib ×19, CPython runtime) in `pilot-03-scope-note.md`. New failure classes surfaced for the loop: (a) transitive-dep RCE mistaken for component_not_present, (b) Debian `no-dsa`/`postponed` ≠ not_affected, (c) advisory-vs-matched-package mismatch (brotli/Scrapy).

**Pilot #3 rationale** (Phase A pick #1): double-untested cell (new language lane *and* new distro tracker) that still allows reliable blind adjudication. Python forces F5 **mode B** (state falsification) — the two-per-cell test of whether the state-falsification rule generalized from Java (pilot 2) holds in a second ecosystem. Debian 13's tracker (`no-dsa`/`postponed`/EOL status semantics differ from Ubuntu) is a real F2-generalization test. Surface at setup: 34 Python + 335 deb + 19 go-module + 10 binary HIGH/CRITICAL.

**Setup rejection (recorded):** original pick `netboxcommunity/netbox:v4.6.2` was rejected during adjudication setup — grype showed base = **ubuntu 26.04** (Debian cell not satisfied) and a Go-dominant surface (9 go / 5 python / 3 deb), which would re-test the covered Go lane. The "verify base at setup" contingency firing as intended.

## Coverage by dimension

| Dimension | ✅ covered | ⬜ untested (priority for Phase A) |
|---|---|---|
| **Language lane** | Go, Java | Python, JS/TS, Rust, C/C++-native |
| **Base distro** | Ubuntu (noble, jammy) | Debian, Alpine, RHEL/UBI, distroless/scratch |
| **Image shape** | single binary, multi-binary, fat/shaded JAR | platform runtime (JRE/Node/CPython) walked, sidecar bundles |
| **Advisory source** | rich GHSA/GO, sparse MSRC | CVE-less (GHSA/GO-only), fresh disclosure (alias-lag window) |
| **Answer direction** | mostly-not_affected, mixed | mostly-affected (stale image), KEV/high-EPSS urgent |
| **Match provenance** | exact PURL | guessed CPE |

## Phase A candidate picks (~6–8) — one per most-untested cell

- [x] Python/Django on **Debian** — stresses F5 mode B without Java's shading; PYSEC advisory quality → **pilot #3 (netbox), adjudicating**
- [ ] Node/TS service on **Alpine** — apk F2 lane (never exercised) + npm advisories
- [ ] **distroless** Go — F3 becomes decisive; no shell/package manager
- [ ] **Rust** CLI — RUSTSEC advisory quality; no free reachability tool
- [ ] deliberately **stale** image — forces the mostly-`affected` direction + F1 prioritization
- [ ] **OpenJDK JRE** platform-runtime lane — pilot 2's 9 bundled-JRE CVEs, left unwalked
- [ ] a **CPE-derived match** target — F1 lower-prior-trust path (never exercised)
- [ ] a **fresh-disclosure** target — F1 `unlinked — recheck` handling (never exercised)

## Phase C holdout (~4–5) — SEAL AT DESIGN TIME, never seen by the improver

- [ ] _reserved_ — one per major lane, ≥1 distroless, ≥1 sparse-advisory-heavy. Fill before Phase B ends.
