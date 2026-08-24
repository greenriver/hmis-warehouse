# 06. Runtime View

## Purpose

This chapter answers one question for a reviewer: **do we understand how the
building blocks actually behave and cooperate while the system runs — for the
handful of situations that matter to the architecture?** Sections 5 and 7 show
the system frozen (what the parts are, where they run); the runtime view shows
it moving. It captures concrete scenarios — a request flowing through the
system, an external hand-off, a start-up, a failure and its recovery — so a
stakeholder who cannot read the static models can still see how the pieces work
together. If a system's hard parts live in its dynamics (a retry protocol, an
ordering constraint, a failure path), a missing or hand-wavy runtime view hides
exactly the risk a reviewer is looking for.

## What belongs here

arc42 does **not** prescribe named subsections for this chapter. Its official
structure is a **sequence of runtime scenarios**, each its own subsection —
`=== <Runtime Scenario 1>`, `=== <Runtime Scenario 2>`, … `=== <Runtime
Scenario n>` in the template. Each scenario documents concrete behavior and
interactions of the building blocks. The template names four *areas* a scenario
may come from:

- **Important use cases or features** — how the building blocks execute them.
- **Interactions at critical external interfaces** — how building blocks
  cooperate with users and neighboring systems.
- **Operation and administration** — launch, start-up, stop.
- **Error and exception scenarios.**

Source (Contents): *"The runtime view describes concrete behavior and
interactions of the system's building blocks in form of scenarios from the
following areas."* These four are a menu to choose from for architectural
relevance, **not** a checklist every document must complete.

Within a single scenario, the template shows two parts: *"insert runtime diagram
or textual description of the scenario"* and *"insert description of the notable
aspects of the interactions between the building block instances depicted."* A
scenario is the steps **plus** what is architecturally notable about them.

## Form & notation

The template offers a menu of notations and expects you to pick one per
scenario; it does not mandate any single one (*"There are many notations for
describing scenarios, e.g."*):

- a **numbered list of steps** in natural language,
- **activity diagrams** or flow charts,
- **sequence diagrams**,
- **BPMN** or EPCs (event process chains),
- **state machines**.

Whichever notation is used, the participants in the scenario are the **building
blocks named in section 5**, and the scenario pairs its steps with a short note
on the notable interaction aspects.

## How much is enough

A **representative selection**, chosen for architectural relevance — not a
catalogue. The template is explicit: *"It is not important to describe a large
number of scenarios. You should rather document a representative selection."*
Tip 6-2 restates it: *"Document only a few runtime scenarios!"* Prefer schematic
over exhaustive detail (Tip 6-3, *"Document 'schematic' (instead of detailed)
scenarios!"*), and an excerpt of a scenario is fine when only part of it is
interesting (Tip 6-6, *"Describe excerpts of scenarios (partial scenarios)!"*).

A lean section 6 with two or three architecturally significant scenarios — say a
critical external hand-off and an error/recovery path — is **complete**, not
deficient; do not flag it for brevity. The chapter is bloated, not thorough,
when it carries one scenario per use case, or step-by-step detail that merely
transcribes the code.

## Example

A good runtime scenario for **RosterRail** (see the example system in
[`../00-index.md`](../00-index.md)). Building-block names refer to blocks defined
in section 5.

> ### Runtime Scenario 1 — Nightly enrollment extract with mid-run failure
>
> *Notation: numbered list of steps.*
>
> 1. `ExtractScheduler` triggers at 02:00 and asks `EnrollmentExtractor` for the
>    day's changed enrollments.
> 2. `EnrollmentExtractor` reads the changed rows from PostgreSQL and hands a
>    batch to `WarehouseClient`.
> 3. `WarehouseClient` POSTs the batch to the external **HMIS Warehouse** over
>    REST, tagging each record with the run's idempotency key.
> 4. The HMIS Warehouse acknowledges partway, then the connection drops before
>    the final acknowledgement.
> 5. `WarehouseClient` records the run as *incomplete* and does not mark the
>    enrollments as sent.
> 6. On the next 02:00 run, `ExtractScheduler` re-sends the full day's records
>    with the same idempotency key; the HMIS Warehouse discards duplicates and
>    stores the remainder.
>
> **Notable aspects:** correctness under failure lives in the idempotency key,
> not in the happy path — the warehouse, not RosterRail, de-duplicates, so a
> partial send is always safe to repeat. `EnrollmentExtractor` never marks rows
> sent until a *complete* acknowledgement returns, which is what makes step 6
> resend the whole day rather than a guessed remainder. This scenario realizes
> the Reliability quality goal from section 1.
>
> ### Runtime Scenario 2 — Case manager opens an unassigned client record
>
> *(A second scenario would follow in the same shape — steps plus notable
> aspects — covering the access-denied path.)*

One scenario shown in full: numbered steps whose actors are named building
blocks, followed by the notable-aspects note. The second heading shows the
chapter is a list of scenarios. That is enough.

## Common mistakes

- **Too many scenarios / one per use case.** Dumping every feature as a scenario
  buries the architecturally relevant ones. Source: *"It is not important to
  describe a large number of scenarios"*; Tip 6-2.
- **Participants that were never introduced.** Steps that name components not
  defined in section 5 (or invented on the spot) cannot be traced. Source:
  Tip 6-1 *"Always map existing building blocks to the activities within runtime
  scenarios!"*
- **Happy path only.** No error/exception scenario and no operational (start-up,
  shutdown) scenario where those are the architecturally interesting parts. The
  template lists both as scenario areas precisely because they are easy to omit.
- **A transcript with no insight.** Steps listed with no statement of what is
  *notable* about the interaction — the template asks for both parts.
- **Re-describing static structure.** Explaining what the building blocks *are*
  instead of how they *behave* — that is section 5's job.

## Belongs elsewhere

- **What the building blocks are, and their static relationships → section 5
  (Building Block View).** The runtime view *uses* those blocks as scenario
  participants; it does not define them.
- **Where components run, and the runtime infrastructure topology → section 7
  (Deployment View).** "Which node handles this" is deployment; "what happens in
  what order" is runtime.
- **General cross-cutting mechanisms (retry, logging, transactions, auth) as
  patterns → section 8 (Crosscutting Concepts).** A scenario may *show* a
  mechanism in action; the reusable description of how it works everywhere
  belongs in section 8.
- **The decision to adopt an approach (e.g. idempotent retry) and its rationale
  → section 9 (Architecture Decisions).** The runtime view shows the approach
  running; the "why this over alternatives" is a decision record.

## Review rules

Severities derive from the arc42 source's own language. The template and its
tips are advisory throughout — even Tip 6-1's *"Always"* sits inside a tip, not
an RFC-2119 mandate — so these are `SHOULD`, not `MUST`. The global
`HOUSE-CODEREF-1` rule in [`../CONVENTIONS.md`](../CONVENTIONS.md) also applies.

- **`A42-6-01` (SHOULD)** — The chapter documents runtime behavior as one or more
  named scenarios, each as its own subsection.
  - *Check:* at least one scenario subsection is present, each with a heading
    that names the scenario; flag a chapter that is undifferentiated prose with
    no scenario structure.
  - *Source:* the upstream chapter is structured as repeated `=== <Runtime
    Scenario n>` subsections —
    <https://raw.githubusercontent.com/arc42/arc42-template/master/EN/adoc/06_runtime_view.adoc>.

- **`A42-6-02` (SHOULD)** — Each scenario gives both a step sequence (or diagram)
  **and** a note on the notable aspects of the interaction.
  - *Check:* every scenario has (a) ordered steps or a diagram, and (b) at least
    a sentence on what is architecturally notable; flag a scenario that has only
    one of the two.
  - *Fail:* a bare numbered list of calls with no notable-aspects note.
  - *Pass:* steps followed by "Notable aspects: correctness under failure lives
    in the idempotency key…".
  - *Source:* the scenario template's two bullets — *"insert runtime diagram or
    textual description"* and *"insert description of the notable aspects of the
    interactions between the building block instances"* —
    <https://raw.githubusercontent.com/arc42/arc42-template/master/EN/adoc/06_runtime_view.adoc>.

- **`A42-6-03` (SHOULD)** — Scenarios are a representative selection, not an
  exhaustive catalogue.
  - *Check:* count the scenarios; flag an enumeration that reads as one scenario
    per use case (e.g. a dozen+ near-identical happy-path flows) rather than a
    chosen handful.
  - *Source:* Remark *"It is not important to describe a large number of
    scenarios. You should rather document a representative selection"*
    (<https://raw.githubusercontent.com/arc42/arc42-template/master/EN/adoc/06_runtime_view.adoc>);
    Tip 6-2 *"Document only a few runtime scenarios!"*

- **`A42-6-04` (SHOULD)** — The participants named in each scenario's steps are
  building blocks defined in section 5.
  - *Check:* each actor/component named in a scenario resolves to a building
    block introduced in the Building Block View; flag names that appear only in
    section 6.
  - *Fail:* "the sync job calls the uploader" where no such blocks exist in
    section 5.
  - *Pass:* steps naming `EnrollmentExtractor` and `WarehouseClient`, both
    defined in section 5.
  - *Source:* Tip 6-1 *"Always map existing building blocks to the activities
    within runtime scenarios!"*; Contents *"interactions of the system's
    building blocks."*

- **`A42-6-05` (SHOULD)** — Each scenario is expressed in one recognizable
  scenario notation, not unstructured narrative.
  - *Check:* each scenario is a numbered step list, an activity/flow diagram, a
    sequence diagram, a BPMN/EPC diagram, or a state machine; flag a scenario
    given as a free-form paragraph with no discernible ordered structure. The
    *choice* of notation is free.
  - *Fail:* a single paragraph narrating "and then it does X and also Y".
  - *Pass:* an ordered numbered-step list, or a sequence diagram.
  - *Source:* Form list of notations (*"There are many notations for describing
    scenarios, e.g. numbered list of steps … sequence diagrams …"*) —
    <https://raw.githubusercontent.com/arc42/arc42-template/master/EN/adoc/06_runtime_view.adoc>.

## Sources

- **Canonical chapter (authoritative for subsection structure and numbering):**
  `06_runtime_view.adoc`, arc42-template 9.0-EN, git SHA `8dff0d9b`, read locally
  from `/tmp/arc42-template/EN/adoc/06_runtime_view.adoc`. Cite by raw URL —
  <https://raw.githubusercontent.com/arc42/arc42-template/master/EN/adoc/06_runtime_view.adoc>.
  Retrieved 2026-08-23.
- **Section page (Contents, Motivation, Form):**
  <https://docs.arc42.org/section-6/>. Retrieved 2026-08-23.
- **Tips used as checkable review criteria:** 6-1 (*"Always map existing building
  blocks to the activities within runtime scenarios!"* — backs `A42-6-04`), 6-2
  (*"Document only a few runtime scenarios!"* — backs `A42-6-03`). From
  <https://docs.arc42.org/section-6/>, retrieved 2026-08-23.
- **Tips informing prose but yielding no separate rule:** 6-3 (schematic over
  detailed) and 6-6 (partial scenarios) inform *How much is enough*; 6-7, 6-8,
  6-9, 6-11 (activity / sequence / textual notations) back the notation rule
  `A42-6-05` but add no rule of their own.
- **Tips skipped** (authoring advice, not review criteria — a later pass may
  revisit): 6-4 (detailed scenarios with caution), 6-5 (use scenarios to
  discover building blocks), 6-10 (mix small and large building blocks).
- **License:** arc42 template CC BY-SA 4.0; attribution in
  [`../00-index.md`](../00-index.md).
