# GHSA-vrg7-482j-p6f6 — granian 2.5.4 (pip) @ paperless-ngx:2.20.15 (ASGI web server)
aliases: [GHSA-vrg7-482j-p6f6, CVE-2026-42544]
match_provenance: purl
image: ghcr.io/paperless-ngx/paperless-ngx@sha256:6c86cad803970ea782683a8e80e7403444c5bf3cf70de63b4d3c8e87500db92f
repo_commit: 05e48b23166df7c7afe6f329b460b0511a89496c
expected_verdict: affected (priority)
expected_justification: "remediation: bump granian to 2.7.4 (unauthenticated pre-auth DoS)"
decisive_rung: F5 + F6 (deploy config: server + WS enabled)
anchor_evidence: >
  Granian aborts a worker when an unauthenticated client sends a WebSocket upgrade whose
  `Sec-WebSocket-Protocol` header has non-ASCII bytes; the crash is in WS scope construction, BEFORE the
  ASGI app runs. Image serves via `granian --interface asginl --ws --loop uvloop paperless.asgi:application`
  (docker/.../svc-webserver/run:17). `--ws` = granian handles the WS upgrade; paperless.asgi routes a
  "websocket" ProtocolTypeRouter (paperless/asgi.py:18-21). Default 1 worker → single request = full outage.
ground_truth_source: GHSA advisory + image webserver run-script + asgi.py; expert adjudication 2026-07-05.
trap: >
  The WS route is wrapped in `AuthMiddlewareStack` (asgi.py:21), tempting a "requires auth → not_affected"
  call. But the granian crash happens PRE-ASGI / PRE-auth, so app-layer auth cannot mitigate it. Also
  don't assume daphne serves WS — the image runs granian with `--ws`. Unauthenticated, network-reachable,
  single-request DoS → affected + priority.
source_pilot: 3 (paperless)
