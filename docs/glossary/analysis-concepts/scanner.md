---
title: "Scanner (vulnerability scanner)"
type: glossary-term
group: analysis-concepts
tags:
  - glossary
---

# Scanner (vulnerability scanner)

A tool that inventories what software is present (an [[sbom|SBOM]] step) and matches it against vulnerability databases: Qualys, Wiz, [[grype]], Docker Scout, Trivy, Clair. Output: "package X version Y matches advisory Z."

Scanners *match*; they do not judge exploitability — that gap is the reason the VEX project exists. They disagree with each other for three reasons: (1) different data-source selections, (2) metadata blind spots ([[vendoring]]), (3) different [[cpe|CPE]]-guessing heuristics.
