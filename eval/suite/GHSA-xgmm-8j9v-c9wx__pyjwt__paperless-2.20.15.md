# GHSA-xgmm-8j9v-c9wx — pyjwt 2.10.1 (pip) @ paperless-ngx:2.20.15
aliases: [GHSA-xgmm-8j9v-c9wx, CVE-2026-48526, PYSEC-2026-179]
match_provenance: purl
image: ghcr.io/paperless-ngx/paperless-ngx@sha256:6c86cad803970ea782683a8e80e7403444c5bf3cf70de63b4d3c8e87500db92f
repo_commit: 05e48b23166df7c7afe6f329b460b0511a89496c
expected_verdict: not_affected
expected_justification: vulnerable_code_not_in_execute_path
decisive_rung: F5 (state falsification — required config absent)
anchor_evidence: >
  Forged-HS256 requires a verifier configured BOTH with mixed symmetric+asymmetric algorithms in
  `algorithms=[…]` AND a raw-JSON JWK passed as `key=` — both explicitly "contrary to documented usage"
  (advisory's own High attack-complexity note). grep of src/ shows no `jwt.decode(` call at all; pyjwt is
  transitive. The specific dangerous configuration provably does not occur.
ground_truth_source: GHSA advisory (precondition note) + absent jwt.decode; expert adjudication 2026-07-05.
trap: >
  A grep for `algorithms=` FALSE-matches paperless's own `MATCHING_ALGORITHMS` enum (documents/models.py:54),
  which is document-matching config, NOT JWT algorithms. Don't anchor on a coincidental identifier match —
  confirm it's a jwt.decode algorithms list before reasoning about it.
source_pilot: 3 (paperless)
