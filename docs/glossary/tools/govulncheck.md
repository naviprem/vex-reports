---
title: "govulncheck"
type: glossary-term
group: tools
tags:
  - glossary
---

# govulncheck

The Go security team's free [[reachability-analysis|reachability analyzer]]. Builds the call graph from source and reports **only** advisories whose vulnerable [[symbol|symbols]] are actually reachable, with example call traces; everything else is pruned.

The reason the pilot targeted a Go project — it's the one ecosystem with free symbol-level reachability. Caveats: exit code 3 means "findings exist" (not an error), and traces through interfaces need sanity-checking ([[interface-dispatch-over-approximation]]). Data source: [[go-vulnerability-database]].
