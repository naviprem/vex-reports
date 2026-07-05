---
title: "Layer"
type: glossary-term
group: container-fundamentals
tags:
  - glossary
---

# Layer

One gzipped tarball holding a filesystem *diff* — the files added, changed, or removed by one build step. A [[container-image]] is an ordered stack of layers; at container start they are union-mounted into one root filesystem.

Gotcha: a file deleted in a later layer still physically exists in the earlier layer's tarball (deletions are "whiteout" markers) — "we `rm`-ed it" does not remove it from the image. [[syft]] tracks which layer contributed each file, powering the component-presence rung (F3) of the [[evidence-ladder]]. See also [[multi-stage-build]].
