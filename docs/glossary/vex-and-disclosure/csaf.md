---
title: "CSAF 2.0 (Common Security Advisory Framework)"
type: glossary-term
group: vex-and-disclosure
tags:
  - glossary
---

# CSAF 2.0 (Common Security Advisory Framework)

The heavyweight, enterprise/regulator-standard JSON format for security advisories, with a [[vex|VEX]] profile. Chosen for Phase 1 of this project.

Requires a *product tree* mapping statements to exact products (for us: `ImageSHA`s — see [[tag-vs-digest]] — and Helm chart versions) and supports machine `flags` ([[justification|justifications]]) plus free-text `impact_statement`. Generated documents must validate against the official schema — a hard gate in rung F7.
