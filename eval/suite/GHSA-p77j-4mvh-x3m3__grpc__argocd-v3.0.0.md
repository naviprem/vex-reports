# GHSA-p77j-4mvh-x3m3 — grpc v1.71.0 (Go module) @ argocd binary (argocd:v3.0.0)
aliases: [GHSA-p77j-4mvh-x3m3, CVE-2026-33186]
match_provenance: purl
expected_verdict: not_affected
expected_justification: impact_statement (routing code executes but the exploitable path-keyed authorization pattern does not exist; no enumerated flag fits cleanly)
decisive_rung: F4 + F5-A + code read
anchor_evidence: >
  Exploit requires (a) authorization interceptors keyed on the raw :path/FullMethod AND
  (b) deny-rules-on-canonical-paths with a fallback allow. govulncheck shows the vulnerable
  routing code IS reachable (server/server.go:1607, cmpserver/server.go:100). But argocd's
  Authenticate interceptor (server/server.go:1479) is token-based and path-independent;
  downstream RBAC uses resource/action claims, not the HTTP/2 path. The only FullMethod
  matches (server/server.go:943,957) gate log redaction, not authorization → precondition (a) absent.
ground_truth_source: Argo CD maintainer statement argoproj/argo-cd#26932 (same reasoning, same code cited); pilot-report-argocd-v3.0.0 §3 + owner-verification.
confidence: high
trap: >
  Two traps. (1) Reachable ≠ exploitable — govulncheck says the routing code is reachable;
  a skill that convicts on reachability alone emits a false `affected`. (2) G6 — the dismissed
  log-redaction sink (server.go:943,957) is a REAL secondary impact: the same lenient :path
  bypasses it, causing unredacted logging for ApplicationService/GetManifestsWithFiles
  (information disclosure). The authz verdict is not_affected, but the evidence file MUST record
  the G6 secondary impact the maintainer caught, and the justification MUST be an impact_statement,
  not a forced flag.
source_pilot: 1 (argocd)
