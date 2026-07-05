---
session_id: "CC-20260704-vu23nd"
title: "Pilot #2: LLM-driven VEX triage of Flyway 11.0.0 (Java lane)"
date: 2026-07-05
type: pilot-report
status: complete
---

# Pilot Report #2: LLM-Driven VEX Triage — Flyway 11.0.0

**Purpose:** stress-test the thesis where pilot #1 (Argo CD, Go) couldn't — a **Java** target, where no free `govulncheck` equivalent exists. Rung F5 runs on advisory-precondition analysis + code reading alone. Also exercises the tier-3 rules on Java's embedding mechanisms (bundled driver JARs, shaded/nested JARs).

**Target:** `docker.io/flyway/flyway:11.0.0` (Redgate's DB migration CLI, ~Dec 2024, Ubuntu 22.04 "jammy" base, bundled JRE 17, bundled JDBC drivers) — digest `sha256:3d61e3babd5e8184be19c8de88965a85ec490b93247c532465337daaaf279d1e`; source `github.com/flyway/flyway` @ `flyway-11.0.0`.
**Toolchain:** grype, syft (full 372-artifact inventory), crane, Ubuntu Security API, OSV API, GitHub issues API, grep/code reading. No reachability engine of any kind.

## Scanner baseline

483 findings (32 High, 0 Critical) in three strata: **435 deb** (jammy packages), **21 binary** (the bundled OpenJDK 17.0.13 JRE — 9 CVEs, the Java analog of pilot #1's bundled Go binaries), **27 java-archive** (Flyway's own libs + bundled JDBC drivers). The gnupg CVE alone fanned across **11 binary debs** from one source package (tier-2 fold: one work item).

## Verdicts (7 items walked)

| Finding | Component (copy) | Verdict | Decisive evidence |
|---|---|---|---|
| CVE-2026-45447 (openssl) | deb `3.0.2-0ubuntu1.18` | **affected** | Ubuntu fix released `…1.25`; image behind |
| CVE-2025-68973 (gnupg2) | 11 debs `2.2.27-3ubuntu2.1` | **affected** (1 work item) | Ubuntu fix released `…2.5`; image behind |
| GHSA-j3rv-43j4-c7qm (jackson PTV bypass) | Flyway's own `2.15.2` @ `/flyway/lib/` | **not_affected** | No polymorphic typing anywhere in source |
| GHSA-j3rv-43j4-c7qm (same CVE) | `2.16.0` **inside** `databricks-jdbc-2.6.38.jar` | **under_investigation** | Third-party shaded copy; can't cheaply inspect |
| GHSA-4g8c-wm8x-jfhw (netty SslHandler native crash) | `4.1.94.Final` @ `drivers/cassandra/` | **not_affected** | Precondition component absent from image |
| GHSA-98qh-xjc8-98pq (pgjdbc SCRAM DoS) | `postgresql-42.7.2.jar` | **not_affected** (caveat) | Requires malicious/compromised DB server |
| GHSA-m494-w24q-6f7w (mssql-jdbc spoofing) | `12.6.3` | **affected** | Advisory too sparse to argue otherwise (G1) |

### Reasoning chains (the Java-lane test)

**jackson-databind, Flyway's own copy → `not_affected` + `vulnerable_code_not_in_execute_path`.**
CVE-2026-54512 bypasses the `PolymorphicTypeValidator` via generic type parameters — but the entire attack surface only exists if the application *enables polymorphic typing*. Repo-wide search: zero occurrences of `activateDefaultTyping`, `enableDefaultTyping`, `PolymorphicTypeValidator`, or `@JsonTypeInfo` in non-test source. `ObjectMapperFactory.java` constructs stock `new JsonMapper()` / `new TomlMapper()` selected by file extension, consuming local configuration files (operator-controlled — the attacker-input precondition fails independently). Two independent kill conditions, both citable. *This is the finding that proves the thesis for Java: no reachability tool was needed because the precondition is a configuration of the library that grep can falsify.*

**Same CVE, second copy (shaded inside the Databricks driver) → `under_investigation`, honestly.**
syft found jackson `2.16.0` *nested inside* `databricks-jdbc-2.6.38.jar` — Java's version of vendoring. Flyway's source says nothing about how Databricks' driver configures its private jackson; inspecting it means decompiling a third-party fat JAR. Per guardrail G1, no evidence → no `not_affected`. Mitigating context recorded: the driver only class-loads when a Databricks URL is used; remediation is a driver update, not a Flyway code change. First `under_investigation` residue across both pilots — the honesty rule producing its intended output.

**netty SslHandler crash → `not_affected` (impact statement).**
The advisory is explicit: the crash occurs "when using native SSLEngine" (netty-tcnative/BoringSSL). The full syft inventory — all 372 artifacts — contains **no tcnative or BoringSSL component**; only the JDK's SSLEngine is possible, which the advisory does not implicate. Deterministic anchor (inventory) + advisory precondition, no code reading required. (Three more netty-handler advisories on the same JAR were spot-checked at F4: SNI pre-allocation is TLS-*server*-side — the Cassandra driver is a client; IPv6 subnet-filter and trust-manager-wrapping depend on driver code paths not walked. Same method applies; not fully walked in this pilot.)

**pgjdbc SCRAM DoS → `not_affected` + `vulnerable_code_cannot_be_controlled_by_adversary`, with an explicit caveat.**
A *malicious PostgreSQL server* can demand an enormous PBKDF2 iteration count, pinning the client CPU. Flyway connects to databases its operator configures — the "adversary" would have to be your own migration target (or a MITM on an unencrypted link). Wrong side of the trust boundary for the standard deployment; the impact statement records the caveat: connecting over untrusted networks without TLS warrants upgrading the bundled driver to ≥ 42.7.11.

**mssql-jdbc → `affected`, because the advisory gave us nothing to argue with.**
MSRC's entire technical detail: "Improper input validation … allows an unauthorized attacker to perform spoofing over a network." Installed 12.6.3 sits in the affected range (12.6.0 → fixed 12.6.5). With no vulnerable symbol, no precondition, no attack description, guardrail G1 forbids `not_affected` — the verdict defaults to affected + bump the bundled driver. **New failure mode documented: sparse advisories cap the ladder at F2-level version logic; F4 needs prose to work with.**

## Owner verification (F4b)

Prior-art search hit on both key CVEs — with the *opposite* pattern from Argo CD:

- flyway#4251 (CVE-2026-54512/jackson) and flyway#4027 (CVE-2025-24970/netty): in both, users report scanner findings and Redgate contributors reply only "updated in Flyway X.Y.Z" — **no exploitability analysis, ever**. Silent-bump is their whole security-response pattern.
- #4027 also documents a real remediation-lag incident: the fix release's Docker image failed to build, leaving `flyway/flyway` users exposed on Docker Hub while other channels had the fix.

**Implication for the thesis:** Argo CD (pilot #1) was the exception — a maintainer team that publishes affectedness analysis. Flyway is the norm: no owner statement will ever exist for these findings, so the VEX document produced by this process is the *only* affectedness statement a Flyway-consuming organization will ever have. Verification against "owner actuals" was only possible for fix *versions*, not verdicts — and our verdicts are consistent with every fact the maintainers did publish.

## What pilot #2 adds beyond pilot #1

1. **The Java lane works without a reachability engine** — jackson's verdict came from precondition falsification (grep + reading mapper construction), not call graphs. Cost profile unchanged: ~2–3 min/finding.
2. **Tier-3 in the wild, twice:** the same CVE required two different verdicts for two copies of the same library in one image (own dependency: `not_affected`; shaded third-party copy: `under_investigation`). Any pipeline that deduped to "one CVE, one verdict" would have gotten one of them wrong.
3. **First honest `under_investigation`** — G1 producing residue instead of a guessed claim.
4. **Sparse-advisory failure mode** (MSRC): when F4 has no prose, the ladder degrades gracefully to version-range logic and an `affected` default. SKILL.md should name this explicitly.
5. **Cross-image recurrence:** CVE-2026-45447 (openssl) and CVE-2025-68973 (gnupg) appeared in *both* pilots' images on different Ubuntu releases — in production, F2 verdicts should be cached per (CVE, distro-release, package-version) and shared across all images on the same base.
6. **The bundled JRE = the platform-runtime lane** (9 CVEs against OpenJDK 17.0.13): same shape as pilot #1's bundled Go binaries — per-binary tier-3 treatment, remediation = newer base/JRE image, walkable by the same ladder (not walked here).

## Combined scorecard (both pilots)

13 findings walked: **7 `not_affected`** (all evidence-cited), **5 `affected`** (all with exact fix versions), **1 `under_investigation`** (honest residue). Zero commercial tools. Marginal cost ~2–3 min/finding after setup.

**Artifacts:** `pilot2/` in the session scratchpad — grype + syft JSON, OSV/Ubuntu/GitHub API responses, flyway source clone.
