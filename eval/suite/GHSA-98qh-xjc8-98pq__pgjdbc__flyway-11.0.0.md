# GHSA-98qh-xjc8-98pq — postgresql (pgjdbc) 42.7.2 @ drivers/ (flyway:11.0.0) — SCRAM DoS
aliases: [GHSA-98qh-xjc8-98pq]
match_provenance: purl
expected_verdict: not_affected (caveat)
expected_justification: vulnerable_code_cannot_be_controlled_by_adversary
decisive_rung: F4 + F6 (trust boundary)
anchor_evidence: >
  A malicious PostgreSQL *server* can demand an enormous PBKDF2 iteration count during SCRAM auth, pinning the
  client CPU. Flyway connects to databases its operator configures — the "adversary" would have to be your own
  migration target, or a MITM on an unencrypted link. Wrong side of the trust boundary for the standard deployment.
ground_truth_source: expert adjudication 2026-07-05; pilot-report-flyway-11.0.0.
confidence: low
trap: >
  Caveat REQUIRED — the verdict rests on a trusted DB server + TLS-in-transit assumption. The evidence file must
  record the revisit trigger: connecting over untrusted networks without TLS re-opens the exposure (then upgrade the
  bundled driver to ≥ 42.7.11). Two failure directions: a skill that reads "DoS" and marks affected fails; a skill
  that marks not_affected but DROPS the caveat also fails (Trap #7 — the attacker is the operator's own configured server).
source_pilot: 2 (flyway)
