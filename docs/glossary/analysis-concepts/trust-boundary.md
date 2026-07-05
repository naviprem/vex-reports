---
title: "Trust boundary"
type: glossary-term
group: analysis-concepts
tags:
  - glossary
---

# Trust boundary

The line between who controls an input and who is harmed by it. Central to exploitability judgments.

Pilot example: the expr CVE required *attacker*-supplied expression strings, but Argo CD's expressions come from an *operator*-controlled ConfigMap — wrong side of the boundary → `not_affected` + `vulnerable_code_cannot_be_controlled_by_adversary`. No static tool evaluates trust boundaries; this is LLM/human territory.
