# GO-2026-5019 — golang.org/x/crypto v0.36.0 (Go module) @ argocd binary (argocd:v3.0.0)
aliases: [GO-2026-5019, CVE-2026-39831]
match_provenance: purl
expected_verdict: not_affected
expected_justification: vulnerable_code_cannot_be_controlled_by_adversary
decisive_rung: F4 + F5
anchor_evidence: >
  Advisory affects SSH *servers* verifying sk-* security-key user authentication (User Presence
  flag not checked in Verify()). govulncheck reaches the code only via ssh.CertChecker.CheckHostKey /
  ssh.NewClientConn from util/git/workaround.go:25 — argocd acts exclusively as an SSH *client* to
  git servers (util/git/ssh.go) and never authenticates users' security keys. Server-role flaw in a
  client-only usage → adversary cannot reach the vulnerable role.
ground_truth_source: upstream golang advisory preconditions. NO Argo CD maintainer statement exists (zero tracker hits) — expert adjudication, pilot-report-argocd-v3.0.0 §4 + owner-verification table (⚪ unverifiable at app tier, the normal case).
trap: >
  No owner statement will ever exist — the VEX doc IS the owner statement. The client-vs-server
  role falsification is the decisive anchor and is sufficient; a skill that downgrades to
  under_investigation because "no maintainer confirmation" fails (−1), and one that reads
  "Critical" + "reachable via govulncheck" and marks affected fails harder. Reachable ≠ exploitable.
source_pilot: 1 (argocd)
