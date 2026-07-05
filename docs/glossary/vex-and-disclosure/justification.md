---
title: "Justification (VEX flags)"
type: glossary-term
group: vex-and-disclosure
tags:
  - glossary
---

# Justification (VEX flags)

The enumerated machine-readable reasons for `not_affected` in [[csaf|CSAF]]/[[vex|VEX]]: `component_not_present`, `vulnerable_code_not_present`, `vulnerable_code_not_in_execute_path`, `vulnerable_code_cannot_be_controlled_by_adversary`, `inline_mitigations_already_exist`.

When none fits precisely, use a free-text `impact_statement` instead of forcing the nearest flag — the pilot's gRPC verdict (code executes, exploitable configuration absent) needed exactly that escape hatch.
