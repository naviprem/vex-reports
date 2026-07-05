---
title: "VEX (Vulnerability Exploitability eXchange)"
type: glossary-term
group: vex-and-disclosure
tags:
  - glossary
---

# VEX (Vulnerability Exploitability eXchange)

A machine-readable statement from a software supplier about whether a product is *actually affected* by a vulnerability in one of its components: `affected` / `not_affected` / `fixed` / `under_investigation`, with a [[justification]].

The answer to [[scanner]] noise: customers' scanners flag your image; your VEX tells them which findings matter. Formats: [[csaf|CSAF 2.0]] (this project's choice), [[openvex-and-cyclonedx-vex|OpenVEX, CycloneDX VEX]].
