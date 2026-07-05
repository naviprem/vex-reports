# GHSA-7p94-766c-hgjp — nltk 3.9.2 (pip) @ paperless-ngx:2.20.15
aliases: [GHSA-7p94-766c-hgjp, CVE-2025-14009, PYSEC-2026-96]
match_provenance: purl
image: ghcr.io/paperless-ngx/paperless-ngx@sha256:6c86cad803970ea782683a8e80e7403444c5bf3cf70de63b4d3c8e87500db92f
repo_commit: 05e48b23166df7c7afe6f329b460b0511a89496c
expected_verdict: not_affected
expected_justification: vulnerable_code_not_in_execute_path
decisive_rung: F5 (state falsification — downloader never invoked)
anchor_evidence: >
  The Zip-Slip RCE is in nltk's DOWNLOADER (`_unzip_iter` → zipfile.extractall in nltk/downloader.py),
  triggered only when nltk.download() fetches+extracts a malicious package. paperless never calls
  nltk.download(): it sets `nltk.data.path = [settings.NLTK_DIR]` (documents/classifier.py:395) and reads
  pre-provisioned, build-time, trusted corpora from that local dir. The vulnerable extract path is never
  on the execute path at runtime.
ground_truth_source: GHSA advisory + classifier.py:395; expert adjudication 2026-07-05.
trap: >
  Critical/RCE severity tempts an `affected` on severity alone. But the vulnerable component (the
  downloader) is never invoked — data is read locally, not downloaded. Don't confuse paperless's own
  document-download endpoint (documents/views.py:1034 `def download`) with nltk.download().
source_pilot: 3 (paperless)
