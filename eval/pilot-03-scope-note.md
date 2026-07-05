# Pilot #3 (paperless-ngx:2.20.15) — scope note for deferred tier-3 lanes

The curated cross-section (18 graded suite entries: 12 Python + 6 deb) deliberately
scoped OUT two bundled lanes, recorded here so the coverage gap is explicit (not silent).
These are **not** graded suite entries.

## go-module lane — 19× Go `stdlib` @ `/usr/sbin/gosu`

All 19 go-module HIGH/CRITICAL findings are Go standard-library advisories compiled into a
single bundled binary, **gosu** (the container's startup privilege-drop tool). One tier-3
work item, per component copy:

- **Same shape as pilot 1** (bundled helm/kustomize/git-lfs Go binaries) and pilot 2 (bundled JRE).
- gosu is invoked once at container start (entrypoint setuid), **not network-facing** — most Go
  stdlib CVEs (net/http, crypto/tls, archive/*) are not on its tiny exec-and-drop path.
- To walk properly: `govulncheck` against gosu's source at its build version, OR scope the VEX
  statement explicitly to "gosu, startup-only, not network-reachable" and say so (never let it
  speak for the app binary).
- Expected shape: mostly `not_affected` (vulnerable_code_not_in_execute_path), remediation =
  newer gosu / base image. Left for a Phase B pass that carries gosu's repo+tag.

## platform-runtime lane — CPython 3.12.12 @ `/usr/local/bin/python3.12`

The interpreter binary itself (1 binary HIGH/CRITICAL). Platform-runtime lane per the SKILL lane
guide — remediation is "newer base/runtime image", walkable by the same ladder. Same treatment
class as pilot 2's bundled OpenJDK JRE. Deferred.

## Why deferred (not skipped)

Per learning-loop-protocol §3, a pilot walks a representative cross-section, not every finding.
These two lanes are already exercised in shape by pilots 1–2; re-walking them here would add
little new failure-class coverage versus the Python mode-B and Debian-F2 lanes this pilot targets.
Recorded as an open coverage item in `target-matrix.md`.
