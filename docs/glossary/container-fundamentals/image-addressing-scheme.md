---
title: "Image addressing scheme"
type: glossary-term
group: container-fundamentals
tags:
  - glossary
---

# Image addressing scheme

`host/organization/repository:tag` — e.g. `quay.io/argoproj/argocd:v3.0.0`. Docker Hub is the one special case where the host is implied: `ubuntu:24.04` really means `docker.io/library/ubuntu:24.04`.

Append `@sha256:…` to pin by digest instead of tag (see [[tag-vs-digest]]). ECR follows the same pattern: `<account>.dkr.ecr.<region>.amazonaws.com/<repo>:<tag>`.
