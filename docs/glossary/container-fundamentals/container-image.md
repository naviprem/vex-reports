---
title: "Container image"
type: glossary-term
group: container-fundamentals
tags:
  - glossary
---

# Container image

A packaged filesystem snapshot plus instructions for what process to launch on it. Not a VM: no kernel, no OS in the bootable sense — containers share the host's kernel.

Physically it is three kinds of content-addressed data: a [[manifest]], an [[image-config|image config]], and [[layer|layers]]. Everything is fetchable as plain HTTPS blobs from a [[registry]], which is why scanners don't need a [[docker-daemon|Docker daemon]].
