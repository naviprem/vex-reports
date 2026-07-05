# GHSA-2xpw-w6gg-jr37 — urllib3 2.5.0 (pip) @ paperless-ngx:2.20.15
aliases: [GHSA-2xpw-w6gg-jr37, CVE-2025-66471]
match_provenance: purl
image: ghcr.io/paperless-ngx/paperless-ngx@sha256:6c86cad803970ea782683a8e80e7403444c5bf3cf70de63b4d3c8e87500db92f
repo_commit: 05e48b23166df7c7afe6f329b460b0511a89496c
expected_verdict: not_affected (caveat)
expected_justification: vulnerable_code_not_in_execute_path
decisive_rung: F5 (streaming API not used against untrusted servers)
anchor_evidence: >
  The decompression-bomb affects urllib3's STREAMING API when reading a compressed body from an untrusted
  server. grep of src/ shows no urllib3 streaming usage (no stream=True / iter_content / resp.raw). urllib3
  is transitive under requests/httpx; paperless's outbound HTTP goes to operator-configured endpoints
  (webhooks, optional tika/gotenberg), not arbitrary attacker-controlled servers streamed via urllib3.
ground_truth_source: GHSA advisory + absent streaming usage; expert adjudication 2026-07-05.
confidence: low
trap: >
  Caveat REQUIRED: verdict rests on outbound targets being operator-configured/trusted. Revisit if a
  feature is added that streams+decompresses responses from user-supplied URLs (e.g. remote document
  fetch). Absent that, the streaming path is not on the execute path against an adversary.
source_pilot: 3 (paperless)
