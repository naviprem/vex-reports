# Learnings Log — vex-draft SKILL.md

Append-only (protocol §1). One entry per miss, in order. Never rewrite history —
a reverted edit stays logged, because "we tried X and it regressed Y" is durable.

Entry template:

```
## <date> — pilot <n> — <finding id>
symptom:      <what the runner got wrong, with the score it earned>
root_cause:   <why — the failure CLASS, not the one CVE>
rule:         <the generalized SKILL.md edit proposed (no CVE/package/project names)>
skill_diff:   <section touched + one-line summary of the change>
regression:   <core-set result: pass / which entries moved>
outcome:      accepted | reverted (+ why)
```

---

<!-- No entries yet. Pilots 1–2 predate the loop; the suite is seeded from them.
     First entry lands after pilot #3 (first Phase A iteration). -->
