# GHSA-j3rv-43j4-c7qm — jackson-databind 2.15.2 @ /flyway/lib/ (flyway:11.0.0) — Flyway's OWN copy
aliases: [GHSA-j3rv-43j4-c7qm, CVE-2026-54512]
match_provenance: purl
expected_verdict: not_affected
expected_justification: vulnerable_code_not_in_execute_path
decisive_rung: F5 (state falsification / mode B)
anchor_evidence: >
  The PolymorphicTypeValidator bypass only has an attack surface if the application enables polymorphic
  typing. Repo-wide search: ZERO occurrences of activateDefaultTyping, enableDefaultTyping,
  PolymorphicTypeValidator, or @JsonTypeInfo in non-test source. ObjectMapperFactory.java constructs
  stock `new JsonMapper()` / `new TomlMapper()` selected by file extension, consuming operator-controlled
  local config files. Two independent kill conditions (feature never enabled; input operator-controlled).
ground_truth_source: expert adjudication 2026-07-05 — no maintainer exploitability statement exists (flyway#4251 only replies "updated in X.Y.Z"). pilot-report-flyway-11.0.0.
confidence: low
trap: >
  THE dedup trap (pairs with GHSA-j3rv-43j4-c7qm__jackson-databind__databricks-shaded): the SECOND copy of
  this same canonical CVE — jackson 2.16.0 shaded inside databricks-jdbc — must get a DIFFERENT verdict
  (under_investigation). Do not let dedup merge the two copies. Also: state-falsification (mode B) is the
  primary F5 mode for Java (no govulncheck) — a skill that only knows path-reachability has no tool here
  and may wrongly default to affected/under_investigation.
source_pilot: 2 (flyway)
