# GHSA-m494-w24q-6f7w — mssql-jdbc 12.6.3 @ drivers/ (flyway:11.0.0) — spoofing
aliases: [GHSA-m494-w24q-6f7w]
match_provenance: purl
expected_verdict: affected
expected_justification: "remediation: bump bundled driver to 12.6.5 (installed 12.6.3 sits in affected range 12.6.0 → fixed 12.6.5)"
decisive_rung: F4 (sparse advisory → version-range default per G1)
anchor_evidence: >
  MSRC's entire technical detail: "Improper input validation … allows an unauthorized attacker to perform
  spoofing over a network." No vulnerable symbol, no precondition, no attack mechanism. Installed 12.6.3 sits
  in the affected range (12.6.0 → fixed 12.6.5). With nothing to falsify, G1 forbids not_affected.
ground_truth_source: MSRC advisory (sparse); expert adjudication, pilot-report-flyway-11.0.0.
confidence: high
trap: >
  THE sparse-advisory trap (Trap #3; SKILL F4 sparse-advisory rule). The advisory names nothing to falsify, so
  the ladder degrades to version-range logic → affected + fix version. A skill that SYNTHESIZES a precondition it
  can then "disprove" (e.g. "spoofing needs feature X, which Flyway doesn't use") fabricates evidence and produces
  a program-killing false not_affected (−10). Do not invent preconditions the advisory doesn't state.
source_pilot: 2 (flyway)
