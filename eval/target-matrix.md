# Target Matrix — 20–25 pilot coverage plan

Per protocol §6. Each dimension needs ≥2 targets before a rule counts as "generalized"
rather than "fit one target". ✅ = exercised by a seeded pilot; ⬜ = untested (Phase A/B fodder).

## Seeded pilots (1–2) — cell assignments

| Pilot | Target | Language | Base distro | Image shape | Advisory quality | Direction | Provenance |
|---|---|---|---|---|---|---|---|
| 1 | argocd:v3.0.0 | Go | Ubuntu noble | single binary (+ bundled go binaries) | rich GHSA/GO | mixed (2 affected / 4 not_affected) | PURL |
| 2 | flyway:11.0.0 | Java | Ubuntu jammy | fat/shaded JAR + bundled JRE + driver JARs | mixed (rich GHSA + sparse MSRC) | mixed (3 affected / 3 not_affected / 1 under_inv) | PURL |

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

- [ ] Python/Django on **Debian** — stresses F5 mode B without Java's shading; PYSEC advisory quality
- [ ] Node/TS service on **Alpine** — apk F2 lane (never exercised) + npm advisories
- [ ] **distroless** Go — F3 becomes decisive; no shell/package manager
- [ ] **Rust** CLI — RUSTSEC advisory quality; no free reachability tool
- [ ] deliberately **stale** image — forces the mostly-`affected` direction + F1 prioritization
- [ ] **OpenJDK JRE** platform-runtime lane — pilot 2's 9 bundled-JRE CVEs, left unwalked
- [ ] a **CPE-derived match** target — F1 lower-prior-trust path (never exercised)
- [ ] a **fresh-disclosure** target — F1 `unlinked — recheck` handling (never exercised)

## Phase C holdout (~4–5) — SEAL AT DESIGN TIME, never seen by the improver

- [ ] _reserved_ — one per major lane, ≥1 distroless, ≥1 sparse-advisory-heavy. Fill before Phase B ends.
