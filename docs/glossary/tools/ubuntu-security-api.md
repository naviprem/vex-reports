---
title: "Ubuntu Security API"
type: glossary-term
group: tools
tags:
  - glossary
---

# Ubuntu Security API

JSON endpoint exposing Ubuntu's per-release fix status for any CVE — no scraping needed: `https://ubuntu.com/security/cves/<CVE-ID>.json`.

Rung F2's ground truth for Ubuntu-based images: it answers "[[distro-backport|backported fix]] already in this version, fix released in version X, or not fixed yet." Debian (security-tracker JSON), RHEL (Security Data API), and Alpine (secdb) have equivalents.
