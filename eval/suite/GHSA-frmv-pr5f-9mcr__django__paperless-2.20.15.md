# GHSA-frmv-pr5f-9mcr — django 5.2.7 (pip) @ /usr/src/paperless (paperless-ngx:2.20.15)
aliases: [GHSA-frmv-pr5f-9mcr, CVE-2025-64459, PYSEC-2025-108]
match_provenance: purl
image: ghcr.io/paperless-ngx/paperless-ngx@sha256:6c86cad803970ea782683a8e80e7403444c5bf3cf70de63b4d3c8e87500db92f
repo_commit: 05e48b23166df7c7afe6f329b460b0511a89496c
expected_verdict: affected
expected_justification: "remediation: bump Django to 5.2.8"
decisive_rung: F4 (core-framework Critical, in affected range)
anchor_evidence: >
  SQL injection via a crafted dict with `_connector` key passed by `**`-expansion to QuerySet.filter()/
  exclude()/get() or Q(). Installed 5.2.7 is in the affected range (5.2 before 5.2.8). This is Django ORM
  core — the sink is not gated by an optional feature. paperless uses dynamic `**`-expanded filters
  (documents/filters.py:138,142,144,497,506), so the ORM code path is exercised.
ground_truth_source: Django security release (CVE-2025-64459); expert adjudication 2026-07-05.
trap: >
  Tempting not_affected: the visible `**` sinks in filters.py all append a fixed suffix
  (f"{field}__id__in") so none can produce a bare `_connector` key. But proving NO path across the whole
  app + django-filter passes an untrusted `_connector` is not achievable — G1's burden for a Critical
  core-framework SQLi one patch behind is not met by inspecting a few sinks. Verdict is affected + bump.
source_pilot: 3 (paperless)
