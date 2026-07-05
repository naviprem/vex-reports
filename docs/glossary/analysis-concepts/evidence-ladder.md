---
title: "Evidence ladder (F1–F9)"
type: glossary-term
group: analysis-concepts
tags:
  - glossary
---

# Evidence ladder (F1–F9)

This project's triage method (defined in `PRD-vuln-triage-plugin.md` §5): an ordered walk from cheap mechanical checks to expensive reasoning, stopping at the first decisive rung.

F1 normalize/dedupe → F2 [[distro-backport|distro tracker]] → F3 component presence → F4 advisory intelligence → F4b prior art → F5 usage/[[reachability-analysis|reachability]] → F6 runtime/config context → F7 verdict & drafting → F8 evidence file → F9 PR. Ordering is the efficiency argument: F1–F3 clear bulk noise mechanically; LLM reasoning (F4–F6) runs only on survivors.
