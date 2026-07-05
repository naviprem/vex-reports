This PRD is structured for an AI agent (like Claude) to understand your current infrastructure, the gap in your security workflow, and the specific automation steps required to bridge them.

---

# PRD: VEX Report Generation & Distribution Automation

## 1. Problem Statement

The organization currently generates a high volume of vulnerability alerts (CVEs) across multiple scanners (Qualys, Wiz, Grype, etc.). Security and engineering teams spend excessive manual effort triaging these vulnerabilities, many of which are non-exploitable "noise." There is no automated process to communicate these findings or "false positive" justifications to customers via standardized, machine-readable VEX (Vulnerability Exploitability eXchange) reports.

## 2. Current State (The "As-Is")

* **Infrastructure:** Kubernetes Helm charts, images in AWS ECR.
* **Existing Tooling:**
  * **Scanners:** Qualys, Wiz, Grype, Docker Scout.
  * **Data Aggregation:** Aggregated vulnerability database (normalized by CVE ID, severity, image/package).
  * **Dashboard:** UI displays vulnerabilities categorized by criticality and scanner source.
* **Process:** Manual triage. No standardized external communication of vulnerability exploitability status.

## 3. Goals

* **Reduce Triage Fatigue:** Automate the filtering of non-exploitable vulnerabilities.
* **Standardize Disclosure:** Generate CSAF 2.0 VEX reports automatically.
* **Communicate Early:** Publish an `under_investigation` statement as soon as a finding is detected, so customers see acknowledgment before analysis completes.
* **Enable Trust** *(Phase 2)*: Provide cryptographically signed (Sigstore/Cosign) reports for enterprise customers.
* **Improve Compliance:** Automate the mapping of vulnerability status to SBOM components.

## 4. Pre-Work (Data Gathering)

Before committing to a reachability vendor or sizing the pipeline, pull statistics from the aggregated vulnerability database:

* **Finding mix:** What % of HIGH/CRITICAL findings are OS/base-image package CVEs vs. application dependency CVEs? This determines how much volume call-graph reachability can actually cover (it only applies to app dependencies in supported languages).
* **Language coverage:** Which languages/ecosystems dominate the app-dependency findings, and does the candidate reachability engine (Semgrep, Endor Labs) support them?
* **Baseline metrics:** Current monthly manual triage volume and current time from CVE detection to customer communication (today: effectively never), to anchor the success metrics in §9.

## 5. Proposed Workflow (The "To-Be")

1. **Ingestion:** Orchestrator watches the vulnerability database for new `HIGH`/`CRITICAL` findings.
   * **Conflict resolution:** Scanners disagree on severity and presence, and alias across CVE/GHSA identifiers. The orchestrator must normalize aliases and apply a defined precedence rule (e.g., highest severity wins for triggering; all scanner sources recorded as evidence).
2. **Immediate Acknowledgment:** On detection, automatically draft and publish a CSAF VEX document with status `under_investigation` for the affected products. No human approval is required for this status (it makes no exploitability claim). The document is re-issued when analysis completes.
3. **Triage Analysis — two lanes by finding type:**
   * **Application-dependency CVEs:** Trigger static call-graph reachability analysis (e.g., Semgrep/Endor Labs) to check if the vulnerable code path is invoked.
     * *If Unreachable:* Draft `not_affected` + justification `vulnerable_code_not_in_execute_path`.
   * **OS/base-image package CVEs:** Call-graph analysis does not apply. Use layer/runtime analysis and configuration evidence instead:
     * Vulnerable package or binary not present in the final runtime layer → `not_affected` + `vulnerable_code_not_present` / `component_not_present`.
     * Vulnerable feature disabled or blocked by configuration → `not_affected` + `inline_mitigations_already_exist`.
   * *If exploitable in either lane:* Draft `affected`, and flag for engineering remediation (Jira). Re-issue as `fixed` once the patched image ships.
   * **LLM-Assisted Evidence Gathering (developer-driven):** A shared `vuln-triage` Claude Code skill (distributed via plugin / shared `.claude/skills/`) encodes the triage methodology for both lanes. The Jira ticket created by the orchestrator includes the command (`/vuln-triage CVE-XXXX-XXXXX`); the owning developer runs it in their repo, where Claude fetches the advisory, inspects the code/Dockerfile/Helm values for actual use of the vulnerable component, maps the conclusion to the CSAF justification taxonomy, and opens the draft PR in the VEX repo with a cited evidence file. Highest value in the OS-package lane (no deterministic tool exists) and as a gap-filler for languages the reachability engine doesn't cover.
4. **VEX Drafting:** System populates the CSAF 2.0 JSON schema, including a product tree that maps each statement to specific `ImageSHA`s and Helm chart versions. The raw analysis output (reachability report, layer diff, config evidence) is archived alongside the draft as the justification record.
5. **Review Loop — Git PR-based:** Drafts land as files in a dedicated VEX Git repository. A Security Architect/Lead approves via PR review.
   * `CODEOWNERS` enforces who may approve which products.
   * `not_affected` and `affected` claims require approval before publication; `CRITICAL`-severity `not_affected` claims require two approvers.
   * The PR diff + linked evidence artifacts constitute the audit trail. Merge to main triggers signing and publication.
6. **Publishing (Phase 1 — unsigned):**
   * Merge to main publishes the validated CSAF JSON to S3 and updates the Dashboard UI with a "VEX Available" badge and link to the report. (The badge becomes "Security Verified" in Phase 2 once signing lands.)
   * Distribution in Phase 1 is via the dashboard and S3 links only; the customer-facing API is a fast-follower (§7).
7. **Lifecycle & Re-issuance:** VEX statements are living documents, not one-shot outputs.
   * **State machine:** `under_investigation` → (`not_affected` | `affected`) → `fixed`. Each transition re-issues the CSAF document with an incremented tracking version and revision history entry.
   * **Corrections:** A published claim invalidated by new evidence (scanner correction, new analysis, new image version) triggers a corrected re-issue through the same PR review path; the CSAF revision history records the correction.
   * **New image versions:** A new `ImageSHA` gets fresh statements — claims do not silently carry forward across builds.

## 6. Requirements (Must-Haves)

* **Two-Lane Triage Evidence:** Reachability engine integration for app-dependency CVEs, plus layer/config analysis for OS-package CVEs. Every `not_affected` claim must carry machine-verifiable technical evidence, archived with the report.
* **CSAF 2.0 Compliance:** Generated JSON must validate against official CSAF schemas, including a well-defined product tree (image → `ImageSHA`, Helm chart → version).
* **Lifecycle Support:** Document versioning, status transitions, and correction/re-issuance must be supported from Phase 1 (required by the early `under_investigation` publication).
* **Auditability:** Every VEX report must map back to a specific `ImageSHA` or Helm chart version, its approving reviewer(s), and its archived evidence.
* **LLM Guardrails:** Claude-drafted justifications are never sufficient evidence on their own for a published claim. The skill's output format must force citations to specific files/lines; the session transcript is archived as part of the auditability record; and the PR review gate applies unchanged. Advisory text and package metadata are untrusted input — the skill runs with read-only access and no publish permissions.

## 7. Phase 2 / Fast-Followers

Deferred from Phase 1 must-haves; expected to follow shortly after launch.

* **Cryptographic Signing:** Automate signing using enterprise-managed keys (AWS KMS) via Cosign; provide a documented customer verification procedure. Until this lands, published reports are unsigned and the dashboard badge reads "VEX Available" rather than "Security Verified."
* **API Exposure:** Provide a versioned endpoint for customers to consume VEX files programmatically (99.9% availability target). Phase 1 distribution is dashboard + S3 links.
* **Headless LLM Triage:** Promote the developer-driven `vuln-triage` skill to orchestrator-driven headless runs (`claude -p` / Agent SDK per new finding, posting the draft PR automatically). Gated on the draft-quality metric in §10 demonstrating reviewers rarely correct Claude-drafted justifications.
* **Governance:** A `not_affected` statement is an attributable claim to customers. Accountability sits with the approving Security Architect per `CODEOWNERS`; statement wording templates receive a one-time legal review. *Note:* even in Phase 1, `not_affected` claims are customer-visible via the dashboard — if Phase 1 launches to external customers before this lands, at minimum the legal review of wording templates should be pulled forward.

## 8. Non-Functional Requirements

* **Publication SLA:** `under_investigation` statement published within **24 hours** of a HIGH/CRITICAL finding entering the aggregated database; final status target within **7 days** (subject to baseline data from §4).
* **Schema validity:** 100% of published documents validate against the CSAF 2.0 schema (CI gate on the VEX repo).

## 9. Out of Scope (For Phase 1)

* Automatic patching/PR generation.
* Direct integration with 3rd-party vulnerability management consoles (e.g., pushing back to Qualys/Wiz).
* Handling legacy non-containerized software.
* Additional VEX formats (OpenVEX, CycloneDX VEX) — CSAF 2.0 only in Phase 1; the internal canonical record should not preclude emitting other formats later.

## 10. Success Metrics

Baselines to be established in Pre-Work (§4); targets below are provisional.

* **Triage Volume:** ≥ 40% reduction in manual HIGH/CRITICAL reviews within two quarters of launch (baseline: current monthly triage count).
* **Time to Acknowledgment:** ≥ 95% of findings have a published `under_investigation` statement within the 24-hour SLA.
* **MTTR to Final Status:** Median time from CVE detection to final-status VEX publication ≤ 7 days.
* **Customer Adoption** *(Phase 2)*: Number of enterprise customers consuming the VEX API/Portal, once the API and verification docs ship.
* **LLM Draft Quality:** % of Claude-drafted justifications approved without correction, tracked from day one. This is the gate for promoting to headless triage (§7).

## 11. Open Questions

* **Phase 1 audience:** Is Phase 1 internal-only (dashboard visible to staff), or already customer-visible? This determines whether the governance legal review (§7) must be pulled forward.
* **SBOM linkage:** The compliance goal references SBOM component mapping, but SBOM generation (e.g., Syft) is not yet in scope. Decide: is SBOM generation a Phase 1 dependency, or does the product tree alone satisfy the compliance goal initially?
* **API authentication** *(Phase 2)*: Is the customer endpoint truly public, or authenticated per customer? To be settled when the API fast-follower is designed.
* **Medium-severity findings:** Phase 1 triggers on HIGH/CRITICAL only; enterprise customers will eventually ask about mediums. Decide the Phase 2 threshold.
* **Reachability vendor selection:** Blocked on the §4 language-coverage data. Note: the `vuln-triage` Claude skill covers language gaps as a non-deterministic triage signal, which may allow deferring the vendor decision if the §4 data shows the deterministic engine would cover only a small share of findings.
* **Aggregated DB primary key:** Some vulnerabilities never receive a CVE (GHSA-only, GO-only advisories), and one flaw carries multiple IDs across scanners. Verify the aggregated DB keys findings on a canonical-vulnerability identity resolved via alias lookup (OSV), not on a CVE-ID column — otherwise CVE-less findings collide or drop silently.
* **Known coverage limit — vendored code:** SBOM-based scanners only see declared packages; statically-embedded/vendored libraries (the zlib pattern) leave no package record and are invisible to the entire pipeline. Accept and document as a known limitation — "no findings" ≠ "no vulnerabilities."

---

### Instructions for the LLM (Claude)

*"Act as a Senior Security Automation Engineer. Using the PRD above, provide a technical implementation plan. Define the architecture for the 'Orchestrator' service (including the two-lane triage router and the VEX lifecycle state machine), the recommended schema for the 'VEX Factory' canonical record, the layout and CI pipeline of the VEX Git review repository, and the integration hooks for my current AWS ECR/Scanner stack."*
