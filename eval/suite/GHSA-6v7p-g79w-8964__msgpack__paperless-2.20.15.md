# GHSA-6v7p-g79w-8964 — msgpack 1.1.1 (pip) @ paperless-ngx:2.20.15
aliases: [GHSA-6v7p-g79w-8964]
match_provenance: purl
image: ghcr.io/paperless-ngx/paperless-ngx@sha256:6c86cad803970ea782683a8e80e7403444c5bf3cf70de63b4d3c8e87500db92f
repo_commit: 05e48b23166df7c7afe6f329b460b0511a89496c
expected_verdict: not_affected
expected_justification: vulnerable_code_cannot_be_controlled_by_adversary
decisive_rung: F5 (vulnerable usage pattern + untrusted input both absent)
anchor_evidence: >
  Crash needs a msgpack Unpacker REUSED after a caught error while unpacking untrusted input. grep of src/
  shows no msgpack / Unpacker usage in app code. msgpack is transitive (channels-redis), which unpacks
  paperless's own internal WebSocket/queue messages over a trusted Redis link — not attacker-controlled —
  and does not reuse an Unpacker after an error.
ground_truth_source: GHSA advisory + absent app usage; expert adjudication 2026-07-05.
trap: >
  Two independent preconditions (the reuse-after-error coding pattern AND untrusted input) both fail. Don't
  mark affected just because msgpack is present and deserialization "sounds dangerous" — the transitive
  user (channels-redis) feeds it trusted internal data.
source_pilot: 3 (paperless)
