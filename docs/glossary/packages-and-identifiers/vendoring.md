---
title: "Vendoring / embedded code"
type: glossary-term
group: packages-and-identifiers
tags:
  - glossary
---

# Vendoring / embedded code

Copying a library's source into your own codebase instead of declaring a dependency. The copy is frozen at paste-time and leaves no package-manager record — invisible to [[sbom|SBOM]] tools and therefore to every [[scanner]]. zlib is the classic: hundreds of products carry private copies, each needing its own patch.

Related pilot case: Go's stdlib bundles `x/net`'s HTTP/2 code (`h2_bundle.go`), so one flaw = advisories against two packages with different remediations (bump the module vs. rebuild with a newer toolchain). These are tier-3 embeddings in F1's three-tier rule: group for analysis, never merge verdicts. Go forks via `replace` directives are slow-motion vendoring — checked in rung F5.
