# Justification Taxonomy — ladder conclusion → CSAF VEX status + justification

Used by rung F7. Map the *decisive rung's finding* to a CSAF 2.0 VEX
`product_status` and, for `known_not_affected`, either an enumerated justification
flag or an impact statement. Never force the nearest flag — a slightly-wrong flag is
worse than a precise impact statement, because downstream consumers act on flags
mechanically.

## Decision tree

```
Decisive finding                                            → status                → justification
─────────────────────────────────────────────────────────────────────────────────────────────────────
F2: installed version contains backported fix               → known_not_affected    → vulnerable_code_not_present
F2: fix released, image behind it                           → known_affected        → remediation: exact fixed version
F3: component absent from final image / builder-stage only  → known_not_affected    → component_not_present
F4: precondition provably cannot hold for any deployment
    (wrong role — client vs server; required feature
    component absent from full inventory)                   → known_not_affected    → flag per row below, or impact_statement
F4/F5: adversary cannot supply/control the triggering
    input in this architecture (operator-controlled
    config; sizes bounded by construction)                  → known_not_affected    → vulnerable_code_cannot_be_controlled_by_adversary
F5-A: vulnerable symbols not reachable from any entry point → known_not_affected    → vulnerable_code_not_in_execute_path
F5-B: enabling call/annotation/config provably never
    occurs (state falsification) — vulnerable code never
    executes                                                → known_not_affected    → vulnerable_code_not_in_execute_path
F5-B variant: code DOES execute, but the exploitable
    configuration is absent                                 → known_not_affected    → impact_statement (no flag fits — see below)
F6: vulnerable feature disabled/blocked in this deployment  → known_not_affected    → inline_mitigations_already_exist
Sparse advisory, in affected range, nothing to falsify      → known_affected        → remediation: bump to fixed version
Uninspectable third-party embed (shaded JAR, static copy)   → under_investigation   → note: "await upstream artifact update"
Analysis incomplete / evidence missing                      → under_investigation   → note: what evidence is missing
Fixed in the deployed version (advisory range excludes it)  → fixed                 → cite the version comparison
```

## Flag definitions (CSAF `flags[].label`)

| Flag | Use when | Do NOT use when |
|---|---|---|
| `component_not_present` | The flagged package/library is not in the final image at all (or only in a discarded build stage). | Component is present but conditionally loaded — that's F6 context, not absence. |
| `vulnerable_code_not_present` | Component present, but the vulnerable code is not — distro backport applied, or the vendored/forked copy predates or excludes the flaw (verified against actual source). | You merely *assume* the backport exists — the tracker must confirm it. |
| `vulnerable_code_not_in_execute_path` | Vulnerable symbols unreachable, or the enabling configuration/annotation never occurs so the code never executes. | The code executes but exploitation needs an absent config → impact_statement. |
| `vulnerable_code_cannot_be_controlled_by_adversary` | Code executes/reachable, but the triggering input is on the wrong side of the trust boundary (operator-controlled expression strings; server-role flaw in a client-only usage; input sizes bounded by construction). | The "adversary" is merely *unlikely* rather than architecturally excluded. Record deployment caveats. |
| `inline_mitigations_already_exist` | A configuration, interceptor, or deployment control in place blocks the exploit path (cite the config line / code). | The mitigation is recommended but not actually deployed. |

## The `impact_statement` escape hatch

When the verdict is `known_not_affected` but no flag's definition matches cleanly,
emit a CSAF `threats` entry with `category: "impact"` (and mirror the reasoning in a
`notes` entry) instead of a flag. Pilot exemplar: gRPC `:path` leniency — the
vulnerable routing code executes, but the exploit requires a path-based authorization
pattern that does not exist in the codebase. Neither "not in execute path" nor
"cannot be controlled" is precisely true; the impact statement carries the exact
reasoning and the reviewer can verify it.

Requirements for an impact statement:
- Names the precondition from the advisory and where it fails (`file:line`).
- Self-contained: readable without the evidence file, verifiable with it.
- Still recommend the upgrade as hygiene where applicable.

## Per-copy statements (tier-3 rule)

One CSAF statement per component copy. Two copies of the same library in one image
(own dependency vs. shaded inside a third-party JAR; per-binary toolchain copies) get
independent statuses — pilot 2 produced `not_affected` and `under_investigation` for
the same CVE in the same image. Never emit a single statement that silently covers
both.

## Caveats

Any verdict resting on a deployment assumption (trust boundary, TLS in transit,
single-tenant operator control) carries a caveat note stating the assumption and the
condition under which the verdict must be revisited. Caveats go in the CSAF `notes`
and in the evidence file.
