---
title: "Multi-stage build"
type: glossary-term
group: container-fundamentals
tags:
  - glossary
---

# Multi-stage build

A Dockerfile pattern where early stages (compilers, build tools) produce artifacts copied into a slim final stage. Only the final stage's [[layer|layers]] ship.

Triage relevance: a vulnerable package present only in a builder stage never reaches the shipped image → `component_not_present` (rung F3 of the [[evidence-ladder]]). [[syft]]'s per-layer bookkeeping is what proves it.
