---
title: "syft"
type: glossary-term
group: tools
tags:
  - glossary
---

# syft

[[sbom|SBOM]] generator (Anchore). Reads package-manager metadata from an image or filesystem **without executing anything**: the dpkg status database, Go binary buildinfo (embedded module lists — how we saw deps inside compiled binaries), lockfiles, nested JARs, plus binary classifiers for famous unmanaged binaries.

Resolves the image into a squashed filesystem while tracking which [[layer]] contributed each file. Emits syft-JSON, SPDX, or CycloneDX; assigns [[purl|PURLs]] deterministically and [[cpe|CPEs]] by dictionary + guessing. Blind spot: [[vendoring|vendored]] code.
