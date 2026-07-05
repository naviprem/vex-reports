---
title: "Registry"
type: glossary-term
group: container-fundamentals
tags:
  - glossary
---

# Registry

An HTTPS service hosting [[container-image|container images]]: Docker Hub, quay.io (Red Hat), ghcr.io (GitHub), AWS ECR. All speak the same protocol — the [[oci|OCI]] Distribution API: `GET` the [[manifest]], `GET` each [[layer]] blob.

That standardization is why the same commands work unchanged against quay.io and a private ECR; only authentication differs (quay.io serves public images anonymously, ECR needs AWS credentials). See [[image-addressing-scheme]].
