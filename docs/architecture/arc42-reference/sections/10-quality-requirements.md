# 10. Quality Requirements

## Purpose

This chapter answers one question for a reviewer: **are the qualities this
architecture must deliver written down concretely enough to tell, later, whether
they were achieved?** Section 1.2 named the top three-to-five quality goals;
section 10 is where the full set of quality requirements lives — the top goals
plus the lesser, "nice-to-have" qualities — each pinned to a specific, measurable
scenario. A quality requirement that reads "the system must be fast" is
unreviewable and untestable; the job of this chapter is to turn such adjectives
into scenarios with numbers. If section 10 is a list of bare adjectives, nothing
downstream — evaluation, testing, architectural trade-offs — has anything to
trace back to.

## What belongs here

arc42 splits this chapter into two official subsections:

- **Quality Requirements Overview** (10.1) — a summary of the quality
  requirements, typically grouped by category or topic (for example the
  categories of ISO 25010:2023 or the Q42 quality model), so a reader sees the
  landscape before the detail. The top goals from section 1.2 are **referenced**
  here, not restated: *"The most important of these requirements have already
  been described in section 1.2. (quality goals), therefore they should only be
  referenced here."* This subsection also captures the lower-importance quality
  requirements — the *nice-to-have* ones — that did not earn a place in section 1.
- **Quality Scenarios** (10.2) — the detailed, concrete scenarios that make each
  quality requirement testable: *"Quality scenarios make quality requirements
  concrete and allow to decide whether they are fulfilled (in the sense of
  acceptance criteria)."* Two kinds are called out as especially useful —
  *usage/application scenarios* (the system's runtime reaction to a stimulus) and
  *change scenarios* (the effect and cost of a modification) — with
  *fault/error/failure scenarios* a third useful kind (Tip 10-7).

If the overview in 10.1 is already precise, specific and measurable, 10.2 may be
skipped: *"If these summary descriptions are already precise, specific enough and
measurable, you may skip section 10.2."*

## Form & notation

- **Overview (10.1)** — *"Use a simple table in which each line contains a
  category or topic and a short description of the quality requirement."*
  Alternatives arc42 offers: a mindmap, or a *quality attribute utility tree*
  (the term [Bass+21] gives the tree that puts "quality" at the root and refines
  it downward). Category vocabularies to lean on: ISO 25010:2023 or Q42.
- **Scenarios (10.2)** — two documented shapes:
  - *Short form* (favoured by Q42): **Context/Background**, **Source/Stimulus**
    (who or what triggers the behaviour), **Metric/Acceptance Criteria** (a
    response with a measure).
  - *Long form* (SEI / [Bass+21]): **Scenario ID**, **Scenario Name**,
    **Source**, **Stimulus**, **Environment**, **Artifact**, **Response**,
    **Response Measure**.
- The through-line for both shapes is *"Ensure that your scenarios are specific
  and measurable"* — a scenario without a metric is not a scenario.

*(Note: Tip 10-2, "Document and explain the specific quality tree", is itself
marked deprecated upstream; prefer the table or mindmap forms above. Do not treat
a missing quality tree as a defect.)*

## How much is enough

An overview grouping the qualities by category, plus a handful of measurable
scenarios for the qualities that actually drive architectural decisions. Do not
manufacture scenarios for qualities nobody cares about — the value is in the few
that constrain design. If 10.1's descriptions already carry metrics, 10.2 may be
omitted entirely and the section is still **complete**, not deficient; do not
flag its absence. Conversely, hundreds of flat, unprioritized scenarios with no
overview is a bloat smell, not thoroughness — that is exactly what 10.1 exists to
summarize. A lean section 10 that references section 1.2 and adds measurable
detail for the top qualities is done.

## Example

A good section 10 for **RosterRail** (see the example system in
[`../00-index.md`](../00-index.md)):

> ### Quality Requirements Overview
>
> | Category (ISO 25010) | Quality requirement                                                                 |
> |----------------------|-------------------------------------------------------------------------------------|
> | Security             | Confidentiality of client records (top goal — see §1.2); staff see only assigned clients. |
> | Reliability          | Nightly HMIS extract recovers cleanly from a failed run (top goal — see §1.2).      |
> | Performance          | Client search stays responsive under normal case-manager load.                      |
> | Maintainability      | A new downstream extract format can be added without touching intake code.          |
>
> *(Top goals are referenced from §1.2, not restated. Rows below the line are the
> lower-priority requirements that section 1 omitted.)*
>
> ### Quality Scenarios
>
> | # | Kind   | Source/Stimulus | Response & measure (acceptance criteria) |
> |---|--------|-----------------|------------------------------------------|
> | QS-1 | Usage  | A case manager searches the client roster during business hours (up to 100 concurrent staff). | Results return within 1 second. |
> | QS-2 | Fault  | The downstream HMIS API is unreachable when the nightly extract runs. | The failure is detected within 60 seconds and an operator is notified; the next run resends the full day with no duplicate warehouse records. |
> | QS-3 | Change | A new enrollment extract format is required by a funder. | The new format is added and shipped within two person-weeks, with no changes to client-intake code. |

Three scenarios — one usage, one fault, one change — each with a triggering
stimulus and a measurable response. That is enough.

## Common mistakes

- **Bare-adjective requirements.** "Fast", "secure", "robust" with no metric are
  untestable. Source: *"Ensure that your scenarios are specific and measurable."*
  - *Fail:* "The system must be highly available."
  - *Pass:* "On loss of the primary database the system resumes read traffic
    within 30 seconds."
- **Restating section 1.2 in full.** The top goals should be *referenced* here,
  not copied. Source: *"they should only be referenced here."*
- **Documenting how a quality is achieved instead of what is required.** A
  caching layer or a retry policy is a *solution*; it belongs in section 4 or 8.
  Section 10 states the requirement and its measure.
- **A flat wall of scenarios with no overview.** Dozens or hundreds of
  undifferentiated scenarios and no 10.1 summary — the reader cannot see which
  qualities matter. Source (10.1 Motivation): *"Often we encounter dozens (or
  even hundreds) of detailed quality requirements … you should try to summarize."*

## Belongs elsewhere

- **The top three-to-five quality goals themselves → section 1.2 (Quality
  Goals).** Section 10 references them and adds the fuller/lesser set. Source:
  *"already been described in section 1.2 … they should only be referenced here."*
- **How a quality is achieved (tactics, patterns, mechanisms) → section 4
  (Solution Strategy) or section 8 (Crosscutting Concepts).** Section 10 is the
  requirement, not the design that satisfies it.
- **Risks arising from a quality requirement that may not be met → section 11
  (Risks and Technical Debt).**

## Review rules

Severities derive from the arc42 source's own language. The template is advisory
throughout — it uses "you should", "you may", and descriptive phrasing rather than
RFC-2119 "must" — so these are `SHOULD`/`MAY`, not `MUST`, even where the source
uses an imperative like "Ensure". The global `HOUSE-CODEREF-1` rule in
[`../CONVENTIONS.md`](../CONVENTIONS.md) also applies.

- **`A42-10-01` (SHOULD)** — The chapter contains an overview of the quality
  requirements (10.1), grouped by category or topic.
  - *Check:* a subsection summarizes the quality requirements as a table
    (category/topic + description), a mindmap, or a quality tree — not only a raw
    scenario list.
  - *Fail:* the chapter jumps straight into individual scenarios with no summary.
  - *Pass:* a table whose rows are quality categories (e.g. Security,
    Performance) each with a short description.
  - *Source:* upstream 10.1 *"An overview or summary of quality requirements"*;
    Form *"Use a simple table in which each line contains a category or topic and
    a short description"* —
    <https://raw.githubusercontent.com/arc42/arc42-template/master/EN/adoc/10_quality_requirements.adoc>.

- **`A42-10-02` (SHOULD)** — The top quality goals from section 1.2 are
  referenced, not restated in full, in this chapter.
  - *Check:* where section 10 repeats a section-1.2 goal, it points back to
    section 1 rather than re-deriving the goal's definition.
  - *Source:* *"The most important of these requirements have already been
    described in section 1.2. (quality goals), therefore they should only be
    referenced here."*; Tip 10-1 *"Move details … to this section 10."*

- **`A42-10-03` (SHOULD)** — Each quality requirement is specific and measurable —
  it carries a metric or acceptance criterion, not a bare adjective.
  - *Check:* every detailed quality requirement / scenario states a measurable
    response (a number, threshold, time bound, or explicit acceptance criterion);
    flag single-adjective entries ("fast", "secure").
  - *Fail:* "The system must be scalable."
  - *Pass:* "The system serves 100 concurrent client searches with a p95 response
    under 1 second."
  - *Source:* *"Ensure that your scenarios are specific and measurable."*;
    10.2 *"allow to decide whether they are fulfilled (in the sense of acceptance
    criteria)."*

- **`A42-10-04` (MAY)** — Section 10.2 (detailed scenarios) may be omitted when
  the 10.1 overview is already precise, specific and measurable. Absence of 10.2
  is not, by itself, a defect.
  - *Check:* if there is no separate scenario subsection, verify the overview
    entries are themselves measurable before flagging anything; do not report a
    missing 10.2 when 10.1 already carries metrics.
  - *Source:* *"If these summary descriptions are already precise, specific enough
    and measurable, you may skip section 10.2."*

- **`A42-10-05` (SHOULD)** — Each quality scenario names a triggering
  source/stimulus and the system's response, following one of arc42's scenario
  shapes.
  - *Check:* every scenario identifies who/what triggers it (source/stimulus) and
    the resulting response; a lone metric with no triggering situation, or a
    situation with no response, is incomplete.
  - *Fail:* "Availability: 99.9%." (no stimulus, no scenario)
  - *Pass:* "When the primary node fails (stimulus), traffic fails over and reads
    resume within 30 seconds (response + measure)."
  - *Source:* short form *"Context/Background … Source/Stimulus … Metric/Acceptance
    Criteria"*; long form *"Source … Stimulus … Response … Response Measure"*;
    Tips 10-5 (usage), 10-6 (change), 10-7 (fault/failure) scenarios.

## Sources

- **Canonical chapter (authoritative for subsection structure and numbering):**
  `10_quality_requirements.adoc`, arc42-template 9.0-EN, git SHA `8dff0d9b`,
  read locally from `/tmp/arc42-template/EN/adoc/10_quality_requirements.adoc`.
  Cite by raw URL —
  <https://raw.githubusercontent.com/arc42/arc42-template/master/EN/adoc/10_quality_requirements.adoc>.
  Retrieved 2026-08-23.
- **Section page (Content, Motivation, Form):**
  <https://docs.arc42.org/section-10/>. Retrieved 2026-08-23.
- **Tips fetched** (checkable review criteria only): 10-1 (keep §1.2 short, move
  detail here), 10-5 (usage scenarios), 10-6 (change scenarios), 10-7
  (fault/error/failure scenarios). All under <https://docs.arc42.org/tips/>,
  retrieved 2026-08-23.
- **Tips skipped** (authoring advice or deprecated, not review criteria — a later
  pass may revisit): 10-2 (quality tree — *marked deprecated upstream*), 10-3 (use
  a mind-map as quality tree), 10-4 (use the quality tree as a checklist), 10-8
  (use scenarios for architecture analysis/evaluation).
- **Q42 quality model** — a pinned extract is held locally in
  [`../quality-model/`](../quality-model/): dimension tags and characteristics in
  `qualities.md`, example scenarios in `requirements.md`. Use it to verify that a
  document's quality labels are real dimensions and that its scenarios follow the
  Context / Trigger / Response / Acceptance Criteria shape. See
  [`../00-index.md`](../00-index.md) for the pinned SHA.
- **Referenced within the source, not independently cited here:** ISO 25010:2023
  as a category vocabulary; Len Bass, Paul Clements, Rick Kazman, *Software Architecture in
  Practice*, 4th ed., 2021 ([Bass+21]) for the Quality Attribute Utility Tree and
  the long-form scenario fields — named in the upstream chapter.
- **License:** arc42 template CC BY-SA 4.0; attribution in
  [`../00-index.md`](../00-index.md).
