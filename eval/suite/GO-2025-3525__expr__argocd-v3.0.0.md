# GO-2025-3525 — expr v1.16.9 (Go module) @ argocd binary (argocd:v3.0.0)
aliases: [GO-2025-3525, CVE-2025-29786]
match_provenance: purl
expected_verdict: not_affected
expected_justification: vulnerable_code_cannot_be_controlled_by_adversary
decisive_rung: F5 + code read
anchor_evidence: >
  Parser memory-exhaustion requires attacker-supplied expression strings. Single non-test use of
  expr.Eval is server/deeplinks/deeplinks.go:88; the expression string (link.Condition) originates
  from SettingsManager.GetDeepLinks (util/settings/settings.go:879) reading the argocd-cm ConfigMap
  (application.links / project.links / resource.links) — operator-controlled configuration, not
  end-user input. The "unbounded input" precondition requires the attacker to author the expression.
ground_truth_source: no maintainer exploitability claim; upstream bumped to v1.17.0 (#22651), users pointed to "A word about security scanners" (#23249). Expert adjudication, pilot-report-argocd-v3.0.0 §6.
trap: >
  Caveat REQUIRED — the verdict rests on the argocd-cm ConfigMap being operator-controlled. The
  evidence file must record the revisit trigger: multi-tenant deployments that grant ConfigMap write
  to semi-trusted tenants flip the trust boundary. A skill that emits a bare not_affected without the
  caveat drops the load-bearing deployment assumption (SKILL F6 caveat rule; Trap #7).
source_pilot: 1 (argocd)
