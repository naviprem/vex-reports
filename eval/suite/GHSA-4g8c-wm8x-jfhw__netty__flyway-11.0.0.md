# GHSA-4g8c-wm8x-jfhw — netty 4.1.94.Final @ drivers/cassandra/ (flyway:11.0.0) — SslHandler native crash
aliases: [GHSA-4g8c-wm8x-jfhw, CVE-2025-24970]  # confirmed via OSV API 2026-07-05 (summary matches: "native crash when using native SSLEngine")
match_provenance: purl
expected_verdict: not_affected
expected_justification: impact_statement (crash requires the native SSLEngine / netty-tcnative-BoringSSL, which is absent from the image; the JDK SSLEngine present is not implicated)
decisive_rung: F4 (advisory precondition) + F3 (full inventory)
anchor_evidence: >
  Advisory is explicit: the crash occurs "when using native SSLEngine" (netty-tcnative / BoringSSL). The full
  syft inventory — all 372 artifacts — contains NO tcnative or BoringSSL component; only the JDK's SSLEngine is
  possible, which the advisory does not implicate. Deterministic anchor (inventory) + advisory precondition, no
  code reading required.
ground_truth_source: upstream advisory precondition + deterministic inventory anchor; pilot-report-flyway-11.0.0.
confidence: medium
trap: >
  The decisive precondition is an ABSENT enabling component (tcnative), provable cheaply from the full inventory
  (F3) — a skill that jumps to code reading or reachability misses the cheaper airtight anchor. Also: netty
  4.1.94.Final here is a CLIENT (Cassandra driver); companion netty-handler advisories on the same JAR
  (e.g. SNI pre-allocation, which is TLS-server-side) fail for a DIFFERENT reason — do not blanket all netty
  CVEs with one verdict; each advisory has its own precondition.
source_pilot: 2 (flyway)
