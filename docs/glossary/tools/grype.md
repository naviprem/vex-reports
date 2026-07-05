---
title: "grype"
type: glossary-term
group: tools
tags:
  - glossary
---

# grype

Vulnerability [[scanner]] (Anchore, [[syft]]'s sibling — it runs syft internally). Matches the inventory against a prebuilt **offline** database, downloaded daily and compiled by [[vunnel]] from ~26 providers: [[nvd|NVD]], GitHub ([[ghsa|GHSA]]), [[go-vulnerability-database|Go vulndb]], distro trackers, plus [[kev|KEV]]/[[epss|EPSS]] enrichment.

Key trick: `grype registry:<image>` scans straight from the [[registry]] — no [[docker-daemon|Docker daemon]], no local pull. Provenance note: record the DB snapshot date with every scan (it can be up to a day stale).
