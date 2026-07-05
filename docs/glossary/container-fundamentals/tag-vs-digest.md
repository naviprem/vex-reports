---
title: "Tag vs. digest"
type: glossary-term
group: container-fundamentals
tags:
  - glossary
---

# Tag vs. digest

A tag (`v3.0.0`, `latest`) is a movable nickname pointing at some [[manifest]]; a digest (`sha256:a874…`) is the immutable truth — the hash of that manifest.

VEX and audit claims must bind to digests: a tag can silently point somewhere else tomorrow. In the pilot, [[crane]] pinned `quay.io/argoproj/argocd:v3.0.0` to its digest before any claims were made.
