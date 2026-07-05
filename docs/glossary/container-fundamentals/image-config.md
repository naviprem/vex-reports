---
title: "Image config"
type: glossary-term
group: container-fundamentals
tags:
  - glossary
---

# Image config

JSON inside a [[container-image]] holding runtime instructions (`Entrypoint`/`Cmd`, env vars, user, ports) and build history. Inert metadata — nothing executes inside an image.

Triage relevance: the entrypoint tells you which binary in the image actually *runs* — key evidence for the runtime-context rung (F6) of the [[evidence-ladder]], e.g. arguing a vulnerable bundled binary is present but never invoked.
