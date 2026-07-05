# GHSA-r6ph-v2qm-q3c2 — cryptography 44.0.3 (pip) @ paperless-ngx:2.20.15
aliases: [GHSA-r6ph-v2qm-q3c2, CVE-2026-26007]
match_provenance: purl
image: ghcr.io/paperless-ngx/paperless-ngx@sha256:6c86cad803970ea782683a8e80e7403444c5bf3cf70de63b4d3c8e87500db92f
repo_commit: 05e48b23166df7c7afe6f329b460b0511a89496c
expected_verdict: not_affected
expected_justification: vulnerable_code_not_in_execute_path
decisive_rung: F5 (vulnerable API not called on untrusted SECT keys)
anchor_evidence: >
  Subgroup attack requires loading an attacker-supplied EC public key on a SECT (binary-field) curve via
  load_der/pem_public_key() or EllipticCurvePublicNumbers.public_key(). grep of src/ shows none of these
  APIs, no EllipticCurve/SECT usage in app code (the only "public key" hits are unrelated comments).
  cryptography is used transitively (Django, etc.); paperless never loads untrusted SECT-curve public keys.
ground_truth_source: GHSA advisory + absent API usage; expert adjudication 2026-07-05.
trap: >
  cryptography is a ubiquitous transitive dep, so "it's used → affected" over-triages. The vuln needs a
  specific API + a rare curve family + attacker-controlled key material — none present. not_affected via
  the vulnerable API not being on the execute path with adversary input.
source_pilot: 3 (paperless)
