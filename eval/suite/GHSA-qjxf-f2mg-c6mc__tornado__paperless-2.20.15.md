# GHSA-qjxf-f2mg-c6mc — tornado 6.5.2 (pip, transitive) @ paperless-ngx:2.20.15
aliases: [GHSA-qjxf-f2mg-c6mc, CVE-2026-31958, PYSEC-2026-140]
match_provenance: purl
image: ghcr.io/paperless-ngx/paperless-ngx@sha256:6c86cad803970ea782683a8e80e7403444c5bf3cf70de63b4d3c8e87500db92f
repo_commit: 05e48b23166df7c7afe6f329b460b0511a89496c
expected_verdict: not_affected
expected_justification: vulnerable_code_not_in_execute_path
decisive_rung: F5 (component present, its server not run)
anchor_evidence: >
  The DoS is in Tornado's HTTP server multipart/form-data parser (too many parts, default 100MB body).
  tornado appears only in uv.lock (transitive) — grep of src/ shows ZERO `import tornado` / `from tornado`.
  paperless serves HTTP via granian (docker/.../svc-webserver/run:17), not Tornado's HTTPServer, so the
  vulnerable multipart parser never runs.
ground_truth_source: GHSA advisory + zero tornado imports + granian run-script; expert adjudication 2026-07-05.
confidence: medium
trap: >
  A web-framework CVE on a package that IS installed but whose server is NOT the one running. Presence of
  tornado in the SBOM does not imply its HTTPServer executes — the actual server is granian. Verify which
  server handles requests before treating a server-side CVE as reachable.
source_pilot: 3 (paperless)
