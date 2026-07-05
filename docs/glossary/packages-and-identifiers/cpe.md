---
title: "CPE (Common Platform Enumeration)"
type: glossary-term
group: packages-and-identifiers
tags:
  - glossary
---

# CPE (Common Platform Enumeration)

[[nvd|NVD]]'s older naming scheme: `cpe:2.3:a:vendor:product:version:…`. Problem: vendor/product are editorial choices that exist nowhere in package metadata, so tools must *guess* candidate CPEs (permuting names, authors, group IDs) plus consult curated dictionaries.

CPE guessing is a major source of scanner false positives/negatives, and one of the three reasons [[scanner|scanners]] disagree. A [[purl|PURL]]-based match deserves more prior trust than a CPE-based one — recorded per finding in F1 provenance.
