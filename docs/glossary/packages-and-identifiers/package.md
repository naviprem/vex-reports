---
title: "Package"
type: glossary-term
group: packages-and-identifiers
tags:
  - glossary
---

# Package

A unit of installable software with a name, version, and metadata, managed by some ecosystem (dpkg/apt for Debian/Ubuntu, apk for Alpine, npm, pip, Go modules…).

The granularity at which [[scanner|scanners]] *report* vulnerabilities — but not the granularity at which vulnerabilities *exist* (that's functions; see [[symbol]] and [[reachability-analysis]]). One [[cve|CVE]] maps to many packages and vice versa — the relationship is many-to-many via version ranges. See [[source-vs-binary-package]] and [[purl|PURL]].
