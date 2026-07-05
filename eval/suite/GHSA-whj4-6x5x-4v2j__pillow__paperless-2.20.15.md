# GHSA-whj4-6x5x-4v2j — pillow 11.3.0 (pip) @ paperless-ngx:2.20.15
aliases: [GHSA-whj4-6x5x-4v2j, CVE-2026-40192]
match_provenance: purl
image: ghcr.io/paperless-ngx/paperless-ngx@sha256:6c86cad803970ea782683a8e80e7403444c5bf3cf70de63b4d3c8e87500db92f
repo_commit: 05e48b23166df7c7afe6f329b460b0511a89496c
expected_verdict: affected
expected_justification: "remediation: bump Pillow to 12.2.0 (FITS decompression-bomb DoS)"
decisive_rung: F5 + F6 (untrusted Image.open)
anchor_evidence: >
  Pillow does not bound GZIP-decompressed data when decoding a FITS image → unbounded memory (OOM DoS).
  paperless calls Image.open() on ingested/rendered document images at paperless_tesseract/parsers.py:115,
  134,143 (also documents/converters.py, barcodes.py, utils.py). Image.open() auto-detects format, so a
  crafted FITS payload reaching any of these is decoded. Ingested files are semi-untrusted.
ground_truth_source: GHSA advisory + Image.open call sites; expert adjudication 2026-07-05.
confidence: high
trap: >
  DoS-severity, not RCE — lower priority than pdfminer/granian, but still affected: no format allowlist
  gates Image.open here, so FITS is reachable from untrusted input. Caveat: exploit requires the crafted
  file to actually reach an Image.open call (mime routing may divert some paths) — record as a revisit
  trigger, but absent proof of non-reachability, G1 keeps it affected.
source_pilot: 3 (paperless)
