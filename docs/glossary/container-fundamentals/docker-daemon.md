---
title: "Docker daemon"
type: glossary-term
group: container-fundamentals
tags:
  - glossary
---

# Docker daemon

The background service (`dockerd`) that pulls, stores, and runs containers on a machine. `docker pull` etc. are requests to it.

Pilot discovery: scanners don't need it — `grype registry:<image>` and friends speak the [[registry]] protocol (the [[oci|OCI]] Distribution API) directly. Our whole pilot ran with the daemon down. Benefits: works in CI, no local image cache to go stale, and you scan exactly the digest you asked for.
