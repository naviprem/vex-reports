---
title: "Interface-dispatch over-approximation"
type: glossary-term
group: analysis-concepts
tags:
  - glossary
---

# Interface-dispatch over-approximation

A static-analysis artifact: calls through an interface (e.g., Go's `io.Writer`) force the call graph to include *every* implementation in the binary, creating phantom paths.

Pilot example: a [[govulncheck]] trace claiming `http.Client.Do → io.Copy → ssh.channel.Write` — an HTTP client does not write to SSH channels. Rung F5 requires sanity-checking interface-mediated traces before treating them as reachable.
