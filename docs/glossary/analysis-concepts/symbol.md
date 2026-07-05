---
title: "Symbol"
type: glossary-term
group: analysis-concepts
tags:
  - glossary
---

# Symbol

A named code entity (function, method, type) in a program. Modern advisories record *vulnerable symbols* (see [[go-vulnerability-database]]); [[reachability-analysis|reachability tools]] check whether your call graph reaches them.

The true granularity at which vulnerabilities exist — beneath [[package]] granularity, which is merely where they're *reported*. The distance between those two granularities is the noise a VEX pipeline closes.
