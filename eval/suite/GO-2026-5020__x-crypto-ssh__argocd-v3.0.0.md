# GO-2026-5020 — golang.org/x/crypto v0.36.0 (Go module) @ argocd binary (argocd:v3.0.0)
aliases: [GO-2026-5020, CVE-2026-39834]
match_provenance: purl
expected_verdict: not_affected
expected_justification: vulnerable_code_cannot_be_controlled_by_adversary
decisive_rung: F4 + F5
anchor_evidence: >
  Trigger is a single Write call larger than 4 GiB on an SSH channel (infinite loop). argocd's SSH
  writes go through go-git pack negotiation (pkt-line sized) and io.Copy (32 KiB buffer → each Write
  ≤ 32 KiB). The govulncheck trace http.Client.Do → io.Copy → ssh.channel.Write is an
  interface-dispatch over-approximation. No code path can issue a multi-GB single write, and an
  adversary cannot induce one.
ground_truth_source: upstream golang advisory precondition. No Argo CD maintainer statement (zero tracker hits) — expert adjudication, pilot-report-argocd-v3.0.0 §5.
trap: >
  Interface-dispatch over-approximation (Trap #5) — the govulncheck trace THROUGH io.Copy is a lie;
  a skill that treats the static trace as a real path convicts falsely. Dismissing the trace triggers
  G6: what breaks if a >4 GiB single write DID reach ssh.channel.Write? — it can't, because io.Copy
  caps each Write at its 32 KiB buffer. The evidence file must record that G6 answer, not just assert
  "over-approximation".
source_pilot: 1 (argocd)
