# GHSA-2qfp-q593-8484 — brotli 1.1.0 (pip) @ paperless-ngx:2.20.15
aliases: [GHSA-2qfp-q593-8484, CVE-2025-6176]
match_provenance: purl
image: ghcr.io/paperless-ngx/paperless-ngx@sha256:6c86cad803970ea782683a8e80e7403444c5bf3cf70de63b4d3c8e87500db92f
repo_commit: 05e48b23166df7c7afe6f329b460b0511a89496c
expected_verdict: not_affected
expected_justification: component_not_present
decisive_rung: F3/F4 (vulnerable consumer absent; advisory is Scrapy-scoped)
anchor_evidence: >
  The advisory (CVE-2025-6176) describes a DoS in **Scrapy's** brotli decompression handling — the flawed
  decompression-bomb protection lives in Scrapy, not in the brotli library. `scrapy` is NOT in uv.lock and
  not imported in src/. paperless has no code that brotli-decompresses untrusted responses. grype matched
  the brotli 1.1.0 library because brotli 1.2.0 shipped a co-mitigation, but the vulnerable consumer is absent.
ground_truth_source: GHSA advisory text (Scrapy) + lockfile (no scrapy); expert adjudication 2026-07-05.
confidence: medium
trap: >
  Advisory-vs-matched-package mismatch: grype flags the brotli LIBRARY, but the CVE is about SCRAPY's use
  of it. A skill that reads "brotli decompression DoS" and marks affected without noticing the advisory
  names Scrapy (absent) mis-triages. Confirm the vulnerable component identity, not just the matched name.
source_pilot: 3 (paperless)
