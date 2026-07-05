# GHSA-wf5f-4jwr-ppcp — pdfminer-six 20250506 (pip, transitive via ocrmypdf) @ paperless-ngx:2.20.15
aliases: [GHSA-wf5f-4jwr-ppcp, CVE-2025-64512]
match_provenance: purl
image: ghcr.io/paperless-ngx/paperless-ngx@sha256:6c86cad803970ea782683a8e80e7403444c5bf3cf70de63b4d3c8e87500db92f
repo_commit: 05e48b23166df7c7afe6f329b460b0511a89496c
expected_verdict: affected (priority)
expected_justification: "remediation: bump pdfminer-six to 20251107 (RCE via untrusted PDF)"
decisive_rung: F5 (transitive reachability) + F6 (untrusted input)
anchor_evidence: >
  RCE: CMapDB._load_data() uses pickle.loads(); a malicious PDF can point CMap loading at an alternate
  `.pickle.gz` path → arbitrary code execution. pdfminer-six is NOT imported by paperless app code (grep:
  zero `import pdfminer`), but the uv.lock shows it is pulled transitively by **ocrmypdf** (pyproject
  `ocrmypdf~=16.12.0`), which paperless runs on every ingested document. Documents arrive from
  semi-untrusted sources (consume folder, email). Untrusted PDF → ocrmypdf → pdfminer CMap path.
ground_truth_source: GHSA advisory + uv.lock dependency graph; expert adjudication 2026-07-05.
confidence: high
trap: >
  THE transitive-dependency trap. A skill that greps the app source for "pdfminer", finds nothing, and
  concludes `component_not_present` / not_affected commits a program-killing −10 on an RCE. The component
  IS present (transitive via ocrmypdf) and processes untrusted PDFs. Reachability rests on ocrmypdf's
  pdfminer usage; not fully traceable this session → G1 keeps it affected, never not_affected.
source_pilot: 3 (paperless)
