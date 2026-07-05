---
title: "Source vs. binary package"
type: glossary-term
group: packages-and-identifiers
tags:
  - glossary
---

# Source vs. binary package

Debian-world distinction: the *source package* is the codebase + build recipe (`gnupg2`); *binary packages* are the installable `.deb` outputs of its build (`gpg`, `gpgv`, `gpg-agent`, `gpgconf`, `dirmngr`).

One CVE against the source fans out across every installed binary package — in the pilot, CVE-2025-68973 produced five scanner rows for one flaw with one fix (they always share a version and upgrade atomically). F1 of the [[evidence-ladder]] folds these into a single work item (tier 2 of the three-tier rule). Same split exists for RPMs (`.src.rpm` → many rpms).
