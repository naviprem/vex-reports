# GHSA-j3rv-43j4-c7qm — jackson-databind 2.16.0 shaded INSIDE databricks-jdbc-2.6.38.jar (flyway:11.0.0)
aliases: [GHSA-j3rv-43j4-c7qm, CVE-2026-54512]
match_provenance: purl
expected_verdict: under_investigation
expected_justification: "note: await upstream artifact update (Databricks driver update — not a Flyway code change)"
decisive_rung: F5 (shaded / nested embed — uninspectable third-party code)
anchor_evidence: >
  syft found jackson 2.16.0 nested inside databricks-jdbc-2.6.38.jar (Java's version of vendoring/shading).
  Flyway's source says nothing about how the Databricks driver configures its private jackson; inspecting it
  means decompiling a third-party fat JAR. Per G1, no positive evidence → no not_affected. Mitigating context
  recorded: the driver only class-loads when a Databricks URL is used; remediation is a driver update.
ground_truth_source: expert adjudication 2026-07-05; pilot-report-flyway-11.0.0. First honest under_investigation residue across both pilots.
trap: >
  THE dedup trap (pairs with GHSA-j3rv-43j4-c7qm__jackson-databind__flyway-lib): SAME canonical GHSA, SAME
  image, DIFFERENT verdict. A pipeline that dedups "one CVE → one verdict" gets one copy wrong; if it stamps
  the flyway-lib not_affected onto THIS uninspectable copy, that is a program-killing false not_affected (−10).
  Honest under_investigation here is a PASS (+2), never a coverage failure — G1 residue is correct output.
source_pilot: 2 (flyway)
