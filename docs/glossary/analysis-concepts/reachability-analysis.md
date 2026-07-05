---
title: "Reachability analysis"
type: glossary-term
group: analysis-concepts
tags:
  - glossary
---

# Reachability analysis

Determining whether the application's code can actually *call* the vulnerable function — one level deeper than "the vulnerable [[package]] is present." Commercial tools (Endor Labs, Semgrep Supply Chain) sell this; Go has it free ([[govulncheck]]).

The pilot's core lesson: **reachable ≠ exploitable**. All four Go findings were symbol-reachable, yet advisory preconditions (rung F4) flipped every one to `not_affected` — the [[trust-boundary]] and configuration context decide, not the call graph alone. See also [[interface-dispatch-over-approximation]].
