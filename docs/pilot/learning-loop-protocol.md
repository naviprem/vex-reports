---
session_id: "CC-20260705-vex-prd"
title: "Learning Loop Protocol: pilot-driven improvement of the vex-draft skill"
date: 2026-07-05
type: protocol
status: draft
---

# Learning Loop Protocol — `vex-draft` SKILL.md

Formalizes how pilots 3+ improve the skill before plugin packaging. Companion to `PRD-vuln-triage-plugin.md` (§11 Rollout — this sits between "pilot" and "v1"). The loop's unit of improvement is **one generalized SKILL.md edit, gated by a regression suite**. Pilots 1–2 were manual iterations of this loop; this document makes the next ones reproducible.

## 0. Sequencing

```
[now]  Extract SKILL.md v0 from pilot-walkthrough-argocd-v3.0.0.md + PRD F1–F9/G1–G6
  →    Seed regression suite from pilots 1–2 (13 findings, expected verdicts)
  →    Phase A: improvement pilots (~6–8, full-depth loop, SKILL.md edits)
  →    Phase B: breadth pilots (~10–12, frozen skill per batch, verify-mode grading)
  →    Phase C: holdout validation (~4–5, never used for edits — the promotion measurement)
  →    Promotion gate met → package as plugin (scripts, templates, marketplace)
  →    v1 pilot teams     → loop continues in PR-review feedback mode (M1)
```

At 20–25 pilots (~150–250 findings) the constraint is **adjudication time, not run time** — the runner costs ~2–3 min/finding, but expert adjudication doesn't scale the same way. The three phases exist to spend blind, derive-from-scratch adjudication only where it buys learning (Phase A) or unbiased measurement (Phase C), and to use the cheaper verify-mode everywhere else (Phase B). A side effect of this scale: the suite becomes a reusable benchmark — the asset that later gates headless mode (PRD §11 step 4) on real numbers instead of vibes.

The plugin's deterministic machinery (`fetch_advisory.py`, `build_csaf.py`, `validate_csaf.py`, etc.) can be built **in parallel** at any point — the loop does not improve those and does not depend on them. Only SKILL.md and the two `references/` files are inside the loop.

## 1. Artifacts

| Artifact | Location | Role |
|---|---|---|
| `skills/vex-draft/SKILL.md` | git, versioned | The artifact under improvement. Every accepted edit = one commit with the motivating failure in the message. |
| `references/justification-taxonomy.md`, `references/evidence-format.md` | git | In scope for loop edits. |
| **Guardrails section (G1–G6)** | inside SKILL.md, marked `<!-- FROZEN -->` | **Not editable by the loop.** Changes require a human PRD-level decision, never a loop iteration. |
| `eval/suite/<CVE-or-GHSA>__<image>.md` | git, one file per finding | Expected verdict + justification flag + decisive rung + anchor evidence + adjudication source (maintainer statement / expert review). Seeded with the 13 pilot findings. |
| `eval/learnings-log.md` | git, append-only | One entry per miss: symptom → root cause → generalized rule → SKILL.md diff → regression result → accepted/reverted. |

### Regression-suite entry format

```markdown
# GHSA-j3rv-43j4-c7qm — jackson-databind 2.15.2 @ /flyway/lib (flyway:11.0.0)
expected_verdict: not_affected
expected_justification: vulnerable_code_not_in_execute_path
decisive_rung: F5 (state falsification)
anchor_evidence: zero occurrences of activateDefaultTyping/enableDefaultTyping/@JsonTypeInfo in non-test source
ground_truth_source: expert adjudication 2026-07-05 (no maintainer statement exists — see pilot-report-flyway §F4b)
trap: second copy of same CVE (shaded in databricks-jdbc) must get a DIFFERENT verdict — do not let dedup merge them
```

The `trap` field records what a regressing skill would plausibly get wrong — it's what makes the entry a real regression test rather than a trophy.

## 2. Roles — three separated contexts

Contamination is the main validity threat: if the session that runs the triage also knows the expected verdicts, the eval measures nothing.

| Role | Context rules | Job |
|---|---|---|
| **Runner** | Fresh Claude session. Gets: SKILL.md, input bundle (findings export, image ref, repo checkout). Gets **no** access to `eval/`, pilot reports, or this protocol. | Execute the ladder, emit verdicts + evidence files. |
| **Grader** | Separate session or script. Gets runner output + `eval/suite/`. | Tier 1 (automatable): verdict + justification-flag exact match. Tier 2 (human): citations are real, decisive, and sufficient for a reviewer to verify without trusting judgment (G5 standard). |
| **Improver** | Separate session. Gets: graded failures, learnings log, SKILL.md. | Propose **one generalized edit per failure class** — a rule that would have prevented the miss, stated so it applies beyond the motivating case. G6 and the sparse-advisory rule are the exemplars of the right altitude. |

## 3. Per-pilot procedure — by phase

### Phase A: improvement pilots (~6–8) — full-depth loop

1. **Select target** to stress an *untested* ladder path (see §6 matrix), not to re-confirm a tested one.
2. **Adjudicate first, run second.** Walk the findings yourself (or with maintainer statements where they exist) and write the expected suite entries **before** the runner sees the target. Blind grading is non-negotiable in this phase — pilots 1–2 got this for free because owner verification happened after the run.
3. **Run**: fresh runner session executes `/vex-draft` per SKILL.md on the input bundle.
4. **Grade**: score per §4. Every mismatch is adjudicated — sometimes the *suite* is wrong (record that too; fixing the eval set is also learning).
5. **Improve**: for each genuine miss, improver proposes one SKILL.md edit. Log it in `learnings-log.md`.
6. **Regression-gate**: re-run the **core regression set** (see below) with the edited SKILL.md, fresh runner context. Accept the edit only if §5 passes; otherwise revert and log why.
7. **Absorb**: add this pilot's findings (with adjudicated verdicts) to `eval/suite/`. The suite must grow every iteration.

### Phase B: breadth pilots (~10–12) — frozen skill, verify-mode grading

Run in **batches of 3–4 pilots against a frozen SKILL.md version**; edits happen only between batches.

1. **Run first** (no prior adjudication): fresh runner per target, findings run in parallel where convenient.
2. **Verify-mode grading**: the grader reviews the runner's *evidence files* the way a Security Architect would (the G5 standard — verify citations, don't trust judgment). Verifying a claimed verdict against its cited evidence is far cheaper than deriving the verdict from scratch; this is also a dress rehearsal for the production M1 review process.
3. **Anti-anchoring spot-check**: for ~20% of findings per batch (weighted toward `not_affected` claims), a second adjudication is done **blind** — derive the verdict without seeing the runner's output, then compare. If blind spot-checks disagree with verify-mode grades more than rarely, verify-mode is being anchored by the runner's framing → widen the blind sample.
4. **Between batches**: failure classes from the batch → one improver edit each → core-set regression gate → new frozen version for the next batch. Adjudicated findings from the batch join `eval/suite/`.

### Regression-suite tiering (needed once the suite passes ~40 findings)

- **Core regression set** (~30–40 findings): every finding that ever motivated an accepted edit, every `trap`-bearing entry, and at least one entry per matrix cell (§6). Runs on **every** accepted edit.
- **Full suite**: runs at batch boundaries and before promotion. At 150+ findings a full re-run is a few hours of agent time — batching keeps that affordable.
- Cache F2 verdicts per (CVE, distro-release, package-version) across runs, as the PRD already specifies — cross-image repeats (openssl/gnupg pattern) make re-runs cheaper as the suite grows, since many deb-lane entries resolve from cache.

### Phase C: holdout validation (~4–5) — the promotion measurement

- Targets selected up front (at matrix-design time, §6) and **never seen by the improver**: no edit may be motivated by a holdout finding, and holdout results never enter `learnings-log.md` while the loop is open.
- Adjudicate-first, blind, full-depth — same rigor as Phase A.
- Run **once**, against the final frozen SKILL.md. This is the unbiased estimate of production M1: performance on the growing eval suite overstates quality (the skill was tuned on it); only the holdout says how the skill does on projects it has never been corrected on.
- If the holdout fails the promotion gate (§7): the holdout findings are *burned* — fold them into the training suite, resume Phase B with new edits, and select fresh holdout targets.

## 4. Scoring — asymmetric by design

The loop's fitness function must make guessing `not_affected` the worst possible move, or it will erode G1 by gradient.

| Runner says → Expected was | Score | Rationale |
|---|---|---|
| Correct verdict + correct flag/impact_statement + decisive citation | **+2** | Full credit |
| Correct verdict, wrong/weak justification or non-decisive citation | **+1** | Verdict right, evidence file wouldn't survive review |
| `under_investigation` where evidence existed for a decisive verdict | **−1** | Honest but lazy — recoverable in review |
| `affected` where `not_affected` was provable | **−2** | Safe-direction error; costs remediation noise, not trust |
| **`not_affected` where `affected`/`under_investigation` was correct** | **−10** | The program-killing error. One of these fails the pilot regardless of totals. |
| Honest `under_investigation` on genuinely uninspectable item (e.g. shaded third-party JAR) | **+2** | Correct — G1 residue is a *pass*, never a coverage failure |
| Tier-3 copies collapsed into one verdict | **−5** per hidden copy | The dedup trap; counts per M2's counting rule |

Do **not** score coverage (% resolved) as a positive term. Coverage is an observability metric (M2), not an optimization target.

## 5. Acceptance gate for a SKILL.md edit

An edit is kept iff **all** hold:

1. **Fixes the motivating failure** — the failed finding now scores +2 on re-run.
2. **Zero regressions** — no previously-passing suite entry drops score.
3. **Generalized** — the edit states a rule/question/procedure, not the answer to one CVE. Litmus: does it name a specific CVE, package, or project? If yes, it belongs in the eval suite, not the skill.
4. **Doesn't touch frozen sections** — G1–G6 and the burden-of-proof language are out of bounds.
5. **One edit per failure class** — batch edits make attribution impossible; if two misses share a root cause, that's one edit.

Reverted edits go in the learnings log too — "we tried X and it regressed Y" is a durable lesson.

## 6. Target selection — coverage matrix for 20–25 pilots

Don't pick 25 targets one at a time; design the set as a matrix so every dimension gets ≥2 targets (two per cell is what distinguishes "rule generalizes" from "rule fit one target"). Dimensions, with what each stresses:

| Dimension | Values to cover | What it stresses |
|---|---|---|
| **Language lane** | Go ✅, Java ✅, Python, JS/TS, Rust, C/C++-native | F5 mode selection: govulncheck vs state-falsification vs pure code reading; RUSTSEC/PYSEC/npm advisory quality varies wildly |
| **Base distro** | Ubuntu ✅ (noble+jammy), Debian, Alpine, RHEL/UBI, distroless/scratch | F2 tracker per distro (only Ubuntu exercised); F3 becomes decisive on distroless |
| **Image shape** | single binary ✅, multi-binary ✅, platform runtime (JRE/Node/CPython), fat/shaded JAR ✅, sidecar-style bundles | Tier-3 rules; the PRD §12 multi-binary open question — resolve it with data |
| **Advisory source quality** | rich GHSA/GO ✅, sparse MSRC-style ✅, CVE-less (GHSA/GO-only), fresh disclosure (alias-lag window) | F4 degradation paths; F1 `unlinked — recheck` handling (never exercised) |
| **Expected-answer direction** | mostly-`not_affected` ✅, mostly-`affected` (stale image), KEV/high-EPSS urgent | Honesty in *both* directions; F1 prioritization ordering |
| **Match provenance** | exact PURL ✅, guessed CPE | F1 lower-prior-trust handling for CPE matches (never exercised) |

Assembly guidance:

- **Phase A picks** (~6–8): one target per *most-untested* cell — e.g. Python/Django on Debian, Node service on Alpine, distroless Go, Rust CLI, a deliberately stale image (mostly-`affected` direction), pilot 2's unfinished OpenJDK JRE lane.
- **Phase B picks** (~10–12): second passes over the same cells with *different* projects, plus combinations (Python-on-Alpine, Java-on-UBI). Popularity helps here — well-known images (nginx, postgres, grafana, airflow, gitlab-runner…) have richer prior-art trails for F4b.
- **Phase C holdout** (~4–5): reserved at design time, one per major lane, at least one distroless and one sparse-advisory-heavy target. Sealed until the loop closes.
- Log the matrix as `eval/target-matrix.md` with each target's cell assignments, so coverage gaps are visible at a glance.

## 7. Promotion gate → package as plugin

With a holdout set, the gate is measured on data the skill was never tuned on. Package when **all** hold on the **Phase C holdout run**:

- **Zero false `not_affected`** (any −10 event on holdout fails promotion outright — see §3 Phase C for the burn-and-retry procedure).
- **Verdict-level accuracy ≥ 90%** across holdout findings (honest `under_investigation` on uninspectable items counts as correct; justification-flag and evidence-wording misses do not count against this number — those keep improving in v1 via PR review).
- **Evidence-quality pass rate ≥ 80%**: the grader, acting as a Security Architect, would approve the evidence file without correction (this is the direct pre-estimate of M1).

And one trend condition from Phase B: the **last batch produced no new failure *classes*** — only instances of known ones. New failure classes still appearing means the matrix has uncovered cells, not that the skill is done.

At promotion: SKILL.md is tagged, the full suite (~150–250 findings, holdout now folded in) ships with the plugin repo as its CI eval, and the loop switches to production mode — every Security Architect correction in PR review becomes a candidate suite entry + candidate edit, validated against the core regression set before any plugin version bump. M1 becomes the loop's ongoing score, and the pilot-phase holdout accuracy is its predicted starting value.

## 8. What this protocol deliberately does not do

- **No autonomous self-editing.** The improver proposes; a human accepts. The keep/revert gate is mechanical, but the merge is not.
- **No guardrail evolution.** If a pilot suggests a guardrail is wrong, that's a PRD discussion, not a loop iteration.
- **No synthetic eval cases.** Every suite entry comes from a real image and a real adjudication. Synthetic CVE scenarios would teach the skill the shape of our imagination, not the shape of scanner noise.
