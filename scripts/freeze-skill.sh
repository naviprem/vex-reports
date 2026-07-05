#!/usr/bin/env bash
#
# freeze-skill.sh — scaffold an isolated Runner workspace for one pilot.
#
# Copies the current vex-draft skill into a directory OUTSIDE this repo, stamps
# the exact git SHA under test, and lays out triage-input/ + vex-out/. The Runner
# session MUST be opened inside that directory so it has no filesystem path to
# eval/, docs/pilot/, or the protocol — the contamination guard in
# docs/pilot/learning-loop-protocol.md §2 ("three separated contexts").
#
# Usage:
#   scripts/freeze-skill.sh <pilot-slug>
#   e.g. scripts/freeze-skill.sh pilot-03-django-debian
#
# Override the destination root with TRIAGE_RUNS_ROOT (default: ~/triage-runs).

set -euo pipefail

usage() { echo "usage: $0 <pilot-slug>   e.g. $0 pilot-03-django-debian" >&2; exit 1; }
[ "$#" -eq 1 ] || usage
SLUG="$1"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL_SRC="$REPO_ROOT/vuln-triage"
RUNS_ROOT="${TRIAGE_RUNS_ROOT:-$HOME/triage-runs}"
DEST="$RUNS_ROOT/$SLUG"

[ -d "$SKILL_SRC" ] || { echo "error: skill source not found at $SKILL_SRC" >&2; exit 1; }
[ -e "$DEST" ]      && { echo "error: $DEST already exists — pick a new slug or remove it" >&2; exit 1; }

# Refuse to freeze an unreproducible skill: the version under test must be a
# committed one (protocol: every accepted edit is a commit).
if [ -n "$(git -C "$REPO_ROOT" status --porcelain -- "$SKILL_SRC")" ]; then
  echo "error: vuln-triage/ has uncommitted changes — commit the skill before freezing" >&2
  echo "       (a frozen skill must be reproducible from a git SHA)" >&2
  exit 1
fi

SHA="$(git -C "$REPO_ROOT" rev-parse HEAD)"
SHORT="$(git -C "$REPO_ROOT" rev-parse --short HEAD)"
SUBJECT="$(git -C "$REPO_ROOT" log -1 --pretty=%s)"
STAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

mkdir -p "$DEST/skill" "$DEST/triage-input" "$DEST/vex-out"

# Freeze the whole plugin tree so references/ relative paths resolve as in prod.
cp -R "$SKILL_SRC/." "$DEST/skill/"

cat > "$DEST/FROZEN.md" <<EOF
# Frozen skill under test — $SLUG

| field | value |
|---|---|
| skill_sha | \`$SHA\` |
| skill_sha_short | \`$SHORT\` |
| commit_subject | $SUBJECT |
| frozen_at | $STAMP |
| source | $SKILL_SRC |

The skill in \`./skill/\` is a point-in-time copy of the above commit. Do not edit
it here — loop edits happen in the repo and are re-frozen into a new pilot dir.
EOF

cat > "$DEST/RUNNER-README.md" <<EOF
# Runner workspace — $SLUG

You are the **Runner** (learning-loop-protocol §2). Your only inputs are the
frozen skill in \`./skill/\` and the bundle in \`./triage-input/\`. You have no
access to expected verdicts, pilot reports, or the protocol — do not seek them.

## Job
Execute the vex-draft skill (\`./skill/skills/vex-draft/SKILL.md\`) on the findings
in \`./triage-input/\`. Walk the evidence ladder per the skill, emit one evidence
file per canonical vulnerability per component copy, the CSAF draft(s), and the
summary verdict table. Write everything to \`./vex-out/\` (pilot mode, F9).

## Do not
- Read anything outside this directory to look up an expected answer.
- Guess \`not_affected\` without positive citable evidence (guardrail G1).
EOF

cat > "$DEST/triage-input/README.md" <<EOF
# Drop the input bundle here (see SKILL.md "Inputs")

- \`findings.json\` — scanner export (grype JSON acceptable) with CVE, package,
  installed version, severity, scanner sources, image reference.
- Image reference — registry URI + digest, recorded below (inspected via
  crane/syft from the registry; no Docker daemon needed).
- Application repo — checked out here (or a sibling path) **at the commit the
  image was built from**.
- Deploy config — Dockerfile / Helm values / chart, in the repo or a given path.

image: <registry-uri>@sha256:<digest>
repo_commit: <sha> (+ how repo<->image mapping was verified)
EOF

echo "Runner workspace scaffolded:"
echo "  $DEST"
echo
echo "next:"
echo "  1. drop the input bundle into $DEST/triage-input/"
echo "  2. open a FRESH terminal:  cd '$DEST' && claude"
echo "  3. run the skill; output lands in $DEST/vex-out/"
echo "  4. copy vex-out/ back to the repo's eval/runs/$SLUG/ to grade"
