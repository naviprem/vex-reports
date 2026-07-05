---
title: "Manifest"
type: glossary-term
group: container-fundamentals
tags:
  - glossary
---

# Manifest

The small JSON table-of-contents of a [[container-image]]: it lists the [[image-config|config]] and every [[layer]] by SHA-256 digest.

The *image digest* is the hash of the manifest — change any byte anywhere in the image and it changes — making it the immutable identity of an image. See [[tag-vs-digest]].
