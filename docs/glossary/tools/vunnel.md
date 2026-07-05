---
title: "vunnel"
type: glossary-term
group: tools
tags:
  - glossary
---

# vunnel

Anchore's feed-aggregation pipeline that builds [[grype]]'s offline database from its upstream providers (visible in `grype db providers` output — 26 sources on our machine).

Why it matters conceptually: grype never queries live databases at scan time; scan results are only as fresh as the last DB build.
