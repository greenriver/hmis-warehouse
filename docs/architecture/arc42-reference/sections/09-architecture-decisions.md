# 09. Architecture Decisions

## Purpose

This chapter answers one question for a reviewer: **can a newcomer retrace why
the important, expensive, or risky choices were made — and what was rejected?**
It is the durable record of architecturally significant decisions and their
rationale, so a decision is not silently reversed later by someone who never saw
the reasoning behind it. It is deliberately short: most decisions either live in
section 4 (the headline strategy) or next to the building block they affect.

## What belongs here

The arc42 template gives this chapter no official subsections — it is a single
place for *"important, expensive, large scale or risky architecture decisions
including rationales,"* where a decision means *"selecting one alternative based
on given criteria."* What belongs is the record of each such decision: what was
decided, why, what alternatives were rejected and on what criteria, and its
current status. Decisions that are minor development choices, or that are already
captured in section 4, do not belong here.

## Form & notation

arc42 offers three interchangeable forms; pick one and use it consistently:

- **ADR (Michael Nygard format)** per decision — the five parts *Title, Context,
  Decision, Status, Consequences*. Written in lightweight Markdown/AsciiDoc kept
  near the code (Tip 9-10). Gernot Starke notes the standard ADR is missing
  *decision criteria*, which he recommends adding (Tip 9-5).
- **A list or table**, ordered by importance and consequences.
- **A separate section per decision** for the most detailed cases.

A mind-map suits small keyword-level decisions; a table scales better for large
ones (Tip 9-4). The form is a free choice — do not flag a document for choosing
one arc42 offers over another.

## How much is enough

Thin by design. Record only decisions that are *"important, expensive, large
scale or risky"* (Tip 9-1) — critical, quality-affecting, unconventional, costly,
or long-lasting. A section 9 holding a short list of such decisions, each with a
rationale, is **complete**. An *empty or near-empty* section 9 is acceptable when
the significant decisions are already captured in section 4 or documented locally
in a building block (section 5) — arc42 explicitly leaves that placement to your
judgement. Do not flag brevity here; flag the *absence of rationale* on the
decisions that are recorded.

## Example

A good decision record for **RosterRail** (see the example system in
[`../00-index.md`](../00-index.md)), in Nygard ADR form:

> ### ADR 7: Nightly HMIS extract over REST, not a message queue
>
> **Status:** Accepted — 2026-03-11
>
> **Context:** RosterRail must push a nightly enrollment extract to the
> downstream HMIS warehouse. The warehouse exposes a REST endpoint; the team has
> no streaming infrastructure and the SLA is "delivered by 06:00 daily," not
> real-time.
>
> **Decision criteria (weighted):** operational simplicity (A), delivery latency
> (C), replay/idempotency on failure (A).
>
> **Decision:** We will send the extract as a nightly batch `POST` to the
> warehouse REST API, keyed so a re-run replaces the day's records idempotently.
>
> **Alternatives rejected:** A Kafka topic streaming enrollments in real time —
> rejected because latency (criterion C) is not a driver and it adds a broker the
> team would have to operate (fails criterion A).
>
> **Consequences:** A failed run is recovered by re-running the whole day, with no
> duplicates in the warehouse. Real-time downstream views are out of scope until
> a future decision supersedes this one.

One decision, one record: a rationale, the rejected alternative *with its reason*,
a status, and a date. That is enough.

## Common mistakes

- **Restating section 4 here.** The headline decisions already summarized in the
  solution strategy should be referenced, not copied. Source: *"Avoid redundancy.
  Refer to section 4, where you already captured the most important decisions."*
- **Recording trivial choices.** Formatting rules, variable naming, or a one-line
  library pick are development choices, not architecture decisions. Source: Tip
  9-1 *"Document only architecturally relevant decisions."*
- **A decision with no "why".** *"We use PostgreSQL"* with no reasoning is
  unreviewable. Source: Tip 9-3 *"The 'why' of any decision is often more
  important for understanding than the pure 'what'."*
- **No rejected alternatives.** Without them a reader cannot tell what was traded
  off. Source: Tip 9-6 *"you should include rejected alternatives together with
  the reasons why these were rejected."*
- **Editing a past decision in place.** Superseded decisions should be marked
  superseded, not overwritten — otherwise the history is lost. Source: Tip 9-9
  *"Don't alter existing information in an ADR ... supersede the ADR by creating a
  new ADR."*

## Belongs elsewhere

- **The overall solution strategy and its top decisions → section 4.** Section 9
  holds the detailed records; section 4 carries the summary. Source: *"Refer to
  section 4, where you already captured the most important decisions."*
- **A decision local to one building block → that building block (section 5
  white box).** arc42 leaves this to judgement: *"whether you better document it
  locally (e.g. within the white box template of one building block)."*
- **Risks that a decision creates → section 11 (Risks and Technical Debt).** The
  decision and its rationale belong here; the residual risk it leaves belongs in
  section 11.

## Review rules

Severities derive from the arc42 source's own language. The template and its tips
are advisory — they use "should" and descriptive phrasing rather than RFC-2119
"must" — so these are `SHOULD`. The global `HOUSE-CODEREF-1` rule in
[`../CONVENTIONS.md`](../CONVENTIONS.md) also applies.

- **`A42-9-01` (SHOULD)** — Each recorded decision states its rationale (the
  "why"), not only what was decided.
  - *Check:* every decision entry contains a reasons/context element; flag any
    entry that is a bare statement of choice.
  - *Fail:* `We use PostgreSQL.`
  - *Pass:* `We use PostgreSQL because the team operates it already and needs its row-level security for client confidentiality.`
  - *Source:* Motivation *"Stakeholders of your system should be able to
    comprehend and retrace your decisions"*; Tip 9-3 *"provide reasons for
    important decisions."* <https://docs.arc42.org/section-9/>,
    <https://docs.arc42.org/tips/9-3/>. Retrieved 2026-08-23.

- **`A42-9-02` (SHOULD)** — Only architecturally significant decisions appear
  here — important, expensive, large-scale, or risky — not minor development
  choices.
  - *Check:* scan the entries; flag any whose subject is a formatting rule,
    naming convention, or otherwise trivial coding choice.
  - *Source:* Contents *"Important, expensive, large scale or risky architecture
    decisions"*; Tip 9-1 *"Document only architecturally relevant decisions."*
    <https://raw.githubusercontent.com/arc42/arc42-template/master/EN/adoc/09_architecture_decisions.adoc>,
    <https://docs.arc42.org/tips/9-1/>. Retrieved 2026-08-23.

- **`A42-9-03` (SHOULD)** — No decision here duplicates one already captured in
  section 4; overlapping decisions are cross-referenced, not restated.
  - *Check:* for each entry, confirm the same decision is not written out in full
    in both section 4 and section 9.
  - *Source:* *"Avoid redundancy. Refer to section 4, where you already captured
    the most important decisions of your architecture."*
    <https://raw.githubusercontent.com/arc42/arc42-template/master/EN/adoc/09_architecture_decisions.adoc>.
    Retrieved 2026-08-23.

- **`A42-9-04` (SHOULD)** — Each significant decision records the alternatives
  considered and why they were rejected.
  - *Check:* each entry names at least one rejected alternative with a reason;
    flag entries that present only the chosen option.
  - *Fail:* a decision listing only the option taken.
  - *Pass:* a decision that names the rejected alternative and the criterion it
    failed.
  - *Source:* Tip 9-6 *"you should include rejected alternatives together with
    the reasons why these were rejected."* <https://docs.arc42.org/tips/9-6/>.
    Retrieved 2026-08-23.

- **`A42-9-05` (SHOULD)** — Each decision carries a date/timestamp.
  - *Check:* every entry (or ADR) has a date; flag undated decisions.
  - *Source:* Tip 9-8 *"decisions (e.g. ADRs) should contain a timestamp
    attribute."* <https://docs.arc42.org/tips/9-8/>. Retrieved 2026-08-23.

## Sources

- **Canonical chapter (authoritative for structure — this chapter has no official
  subsections):** `09_architecture_decisions.adoc`, arc42-template 9.0-EN, git
  SHA `8dff0d9b`, read locally from
  `/tmp/arc42-template/EN/adoc/09_architecture_decisions.adoc`. Cite by raw URL —
  <https://raw.githubusercontent.com/arc42/arc42-template/master/EN/adoc/09_architecture_decisions.adoc>.
  Retrieved 2026-08-23.
- **Section page (Contents, Motivation, Form):**
  <https://docs.arc42.org/section-9/>. Retrieved 2026-08-23.
- **Tips fetched — used as review criteria:** 9-1 (significant only), 9-3
  (reasons), 9-6 (rejected alternatives), 9-8 (timestamp); 9-9 (immutable /
  one-decision-per-ADR) informs *Common mistakes*. All under
  <https://docs.arc42.org/tips/> (e.g. <https://docs.arc42.org/tips/9-1/>).
  Retrieved 2026-08-23.
- **Tips fetched — inform prose only, no separate rule:** 9-2 (decision
  criteria — feeds the Example and Form), 9-4 (mind-map vs table — Form), 9-5
  (ADR/Nygard format — Form), 9-10 (lightweight tooling — Form).
- **Tips skipped — authoring/process advice, not review criteria (a later pass
  may revisit):** 9-7 (informal decisions as a blog/RSS feed). Section 9 has no
  tip 9-11 (404).
- **License:** arc42 template CC BY-SA 4.0; attribution in
  [`../00-index.md`](../00-index.md).
