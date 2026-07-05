---
title: "PURL (Package URL)"
type: glossary-term
group: packages-and-identifiers
tags:
  - glossary
---

# PURL (Package URL)

A standardized package identifier that is a valid URI: `pkg:type/namespace/name@version?qualifiers`, e.g. `pkg:deb/ubuntu/openssl@3.0.13-0ubuntu3.5?distro=ubuntu-24.04`. The `pkg:` prefix is the URI *scheme*, literally meaning "package" — constant in every PURL ever written.

Constructed *deterministically* by [[sbom|SBOM]] tools from observed facts (which cataloger fired → type; distro → namespace; package record → name@version) — essentially never wrong. The modern join key for vulnerability matching, unlike guessed [[cpe|CPEs]].
