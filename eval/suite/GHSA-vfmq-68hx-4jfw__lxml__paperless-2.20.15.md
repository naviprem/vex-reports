# GHSA-vfmq-68hx-4jfw — lxml 6.0.2 (pip) @ paperless-ngx:2.20.15
aliases: [GHSA-vfmq-68hx-4jfw, CVE-2026-41066, PYSEC-2026-87]
match_provenance: purl
image: ghcr.io/paperless-ngx/paperless-ngx@sha256:6c86cad803970ea782683a8e80e7403444c5bf3cf70de63b4d3c8e87500db92f
repo_commit: 05e48b23166df7c7afe6f329b460b0511a89496c
expected_verdict: not_affected
expected_justification: inline_mitigations_already_exist
decisive_rung: F6 (explicit parser hardening)
anchor_evidence: >
  XXE-to-local-files affects the DEFAULT config (resolve_entities=True) of `iterparse()` and
  `ETCompatXMLParser()`. paperless's only untrusted-XML parse is reject_dangerous_svg()
  (src/paperless/validators.py:187-189): it constructs `etree.XMLParser(resolve_entities=False)` — the exact
  workaround the advisory names — and uses XMLParser, not the vulnerable iterparse/ETCompatXMLParser. The
  XXE precondition provably cannot hold.
ground_truth_source: GHSA advisory + validators.py:187; expert adjudication 2026-07-05.
confidence: medium
trap: >
  paperless DOES call etree.parse() on untrusted uploads, so a shallow "lxml is used on user input →
  affected" is wrong — the load-bearing detail is the explicit `resolve_entities=False` on the parser
  object. The anchor is that one line; without reading it a grader can't verify the mitigation.
source_pilot: 3 (paperless)
