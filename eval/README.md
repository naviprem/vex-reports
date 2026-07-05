# eval/ — the learning-loop regression suite & run records

Companion to `docs/pilot/learning-loop-protocol.md`. This is the **Grader/Improver**
side of the loop; it holds the answers and must never be visible to a Runner session
(protocol §2).

## Layout

| Path | Role |
|---|---|
| `suite/<CANONICAL-ID>__<component>__<image>.md` | One expected-verdict entry per finding per component copy (protocol §1 format). Seeded from pilots 1–2 (13 findings); grows every pilot. |
| `runs/<pilot-slug>/` | A Runner's `vex-out/` copied back here for grading. One dir per pilot run. |
| `learnings-log.md` | Append-only: one entry per miss (symptom → root cause → rule → diff → regression result → accepted/reverted). |
| `target-matrix.md` | The §6 coverage matrix; each pilot's cell assignments + Phase A/C candidate picks. |

## The physical separation (why runs/ exists)

The Runner works in an isolated workspace **outside this repo** (default
`~/triage-runs/<slug>/`), scaffolded by `scripts/freeze-skill.sh`. It sees only a
frozen copy of the skill and the input bundle — never this directory. After it
writes `vex-out/`, copy that into `eval/runs/<slug>/` and grade it here against
`suite/`.

```
scripts/freeze-skill.sh pilot-03-django-debian   # freeze skill -> ~/triage-runs/
# ... drop triage-input/, run a fresh `claude` session there, it writes vex-out/ ...
cp -R ~/triage-runs/pilot-03-django-debian/vex-out eval/runs/pilot-03-django-debian
# ... grade eval/runs/pilot-03-.../ against eval/suite/ ...
```
