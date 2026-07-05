---
title: "OCI (Open Container Initiative)"
type: glossary-term
group: container-fundamentals
tags:
  - glossary
---

# OCI (Open Container Initiative)

The standards body (under the Linux Foundation) that turned Docker's formats into vendor-neutral specs: the **Image spec** ([[manifest]]/[[image-config|config]]/[[layer|layers]]), the **Distribution spec** (the [[registry]] HTTPS API), and the **Runtime spec** (how to run a container).

"OCI image" ≈ "Docker image." The standardization is why [[grype]], [[syft]], and [[crane]] interoperate with every registry.
