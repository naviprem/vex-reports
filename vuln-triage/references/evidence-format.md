# Evidence File Format

Used by rung F8. One file **per canonical vulnerability per component copy**, named:

```
evidence/<CANONICAL-ID>__<component>@<location>.md
# e.g. evidence/GHSA-j3rv-43j4-c7qm__jackson-databind@flyway-lib.md
#      evidence/GHSA-j3rv-43j4-c7qm__jackson-databind@databricks-jdbc-shaded.md
```

The file is written for a Security Architect who will **verify citations, not trust
judgment** (G5). Every load-bearing claim must be checkable from the file alone:
verbatim tool output, `file:line`, or URL. If a reviewer would have to re-run your
analysis to check a claim, the file is incomplete.

## Required structure

```markdown
---
canonical_id: GHSA-XXXX-XXXX-XXXX          # one canonical vulnerability
aliases: [CVE-XXXX-XXXXX, GO-XXXX-XXXX]    # all known; or "unlinked — recheck"
component: <package name>
installed_version: <version>
location: </path/in/image or embedding>    # distinguishes tier-3 copies
image: <registry uri>@sha256:<digest>
repo_commit: <sha>                          # + how repo↔image mapping was verified
scanner_sources: [grype, ...]
db_snapshot: <scanner DB built date>
match_provenance: purl | cpe                # cpe ⇒ identity was re-verified (say how)
severity: <scanner severity> (KEV: yes/no, EPSS: <score>)
verdict: not_affected | affected | fixed | under_investigation
justification: <flag | impact_statement | n/a>
decisive_rung: F2 | F3 | F4 | F4b | F5 | F6 | none
date: YYYY-MM-DD
tool_versions: {syft: x.y, crane: x.y, govulncheck: x.y, ...}
---

## Verdict

One paragraph: the verdict, the decisive evidence, and (for not_affected) the
precondition that fails and where. This must stand alone.

## Ladder walk

One subsection per rung actually walked, in order. Rungs skipped for a stated reason
(tool missing, not applicable to lane) get one line saying so — never silence.

### F<N> — <rung name>

- **Checked:** what question this rung asked here.
- **Command / source:**
  ```
  <exact command run, or URL fetched>
  ```
- **Output (verbatim, trimmed):**
  ```
  <relevant lines exactly as produced; mark elisions with […]; never paraphrase
   inside the fence>
  ```
- **Interpretation:** what the output means for this finding — the reasoning that
  bridges anchor to conclusion.
- **Citation:** file:line / URL / "output above".

## G6 check (when any sink or trace was dismissed)

For each dismissed candidate consumer or over-approximated trace: what was dismissed,
why, and the answer to "what breaks if malformed input reaches it anyway?"

## Caveats & revisit triggers

- Deployment assumptions this verdict rests on (trust boundary, config, tenancy).
- Conditions that invalidate it (e.g. "revisit if ConfigMap write is granted to
  semi-trusted tenants"; "recheck alias linkage after <date>").
- For under_investigation: exactly what evidence is missing and where it would come from.

## Remediation

Exact fix version(s) where known; direct vs. transitive; whether remediation is a
code change, dependency bump, base-image refresh, or "await upstream artifact".
Priority flag + reason if F6 context aggravates.
```

## Rules

1. **Verbatim means verbatim.** Tool output inside fences is copied, not summarized.
   Trim irrelevant lines with a visible `[…]` marker.
2. **Anchor-first.** If a claim could have a deterministic anchor and doesn't, either
   get the anchor or move the claim to "Interpretation" and mark it as reasoning.
3. **No orphan verdicts.** The frontmatter `verdict` must be derivable from the
   Ladder walk section alone.
4. **Tier-3 copies never share a file.** Shared advisory analysis (F4/F4b) may be
   duplicated across the copies' files or written once and referenced by relative
   link — but the F5/F6 sections and verdict are always per copy.
5. **Preserve the session transcript** alongside the evidence files as part of the
   audit record (G5) — in the PR (F9) or the run's output directory.
