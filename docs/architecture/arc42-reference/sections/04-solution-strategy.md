# 04. Solution Strategy

## Purpose

This chapter answers one question for a reviewer: **what are the few fundamental
decisions that shape this architecture, and why were they made?** It is the
short list of cornerstone choices — the technology stack, the top-level
decomposition, how the key quality goals are met — from which every later
detailed decision follows. If a reviewer cannot see the big moves here, the
detailed chapters (5, 6, 8) have no rationale to trace back to.

## What belongs here

arc42 gives this chapter no official subsections. It asks for a short summary of
the fundamental decisions and solution strategies that shape the architecture,
across four kinds of decision:

- **Technology decisions** — the significant technology choices (language,
  framework, datastore, integration style).
- **Top-level decomposition** — how the system is split at the highest level,
  e.g. an architectural or design pattern.
- **Approaches to key quality goals** — the tactic taken to achieve each top
  quality goal from section 1.
- **Relevant organizational decisions** — e.g. the development process, or
  delegating work to a third party.

Source: *"technology decisions … decisions about the top-level decomposition …
decisions on how to achieve key quality goals … relevant organizational
decisions."*

## Form & notation

- **Keywords or a short list** — arc42 explicitly wants this compact. Tip 4-1:
  *"Explain your solution strategy in keywords, e.g. as a short list of relevant
  decisions or approaches."*
- **A quality-goal table (recommended)** — mapping each quality goal to a
  scenario, the solution approach, and a link to where the detail lives. Tip
  4-2 gives the four columns: *Quality goal · Scenario · Solution approach ·
  Link to Details*.
- **Rationale, not just the choice** — motivate each decision. Form: *"Motivate
  what you have decided and why you decided that way."*

## How much is enough

This is the shortest chapter in the template by design. arc42 says *"Keep the
explanations of such key decisions short"* — three to seven cornerstone
decisions, each a sentence or two of what-and-why, plus an optional quality-goal
table, is **complete**. Detail belongs in sections 5 and 8; a solution strategy
that starts reproducing class designs or configuration has outgrown its job. Do
not flag a lean section 4 for brevity — brevity is the requirement here.

## Example

A good section 4 for **RosterRail** (see the example system in
[`../00-index.md`](../00-index.md)):

> **Cornerstone decisions**
>
> - **Ruby on Rails monolith** over microservices — one small team, one
>   deployable unit keeps operational overhead low.
> - **PostgreSQL as the single source of truth** — relational integrity for
>   client/enrollment data, and one datastore to back up and reason about.
> - **External SSO for staff auth** — the agency already runs an identity
>   provider; delegating auth avoids storing credentials.
> - **Nightly batch extract to the HMIS warehouse** over live sync — the
>   downstream contract is a daily REST push, so a scheduled job is simpler and
>   idempotent.
>
> **How key quality goals are met**
>
> | Quality goal    | Scenario                                                        | Solution approach                                              | Details          |
> |-----------------|-----------------------------------------------------------------|----------------------------------------------------------------|------------------|
> | Confidentiality | Case manager opens a client they are not assigned to            | Row-scoped authorization policy checked on every record access | §8 Authorization |
> | Reliability     | Nightly extract fails mid-run                                   | Idempotent full-day resend keyed on record identity            | §6 Extract run   |

Four keyword decisions with a why, and two quality goals tied to an approach and
a pointer. That is enough.

## Common mistakes

- **What without why.** Listing "we use Rails, PostgreSQL, React" with no
  rationale. Source (Tip 4-6): *"Explain **why** you or your team took certain
  decisions. The 'why' is often more important than the 'what' or 'how'."*
- **Detail that belongs in 5 or 8.** Full component designs, class diagrams, or
  configuration pasted here instead of in the building-block or concepts
  chapters. Tip 4-1: detail explanations belong in section 8.
- **A technology inventory with no link to goals.** Naming the stack but never
  connecting a choice to a quality goal or constraint it serves.

## Belongs elsewhere

- **Detailed decomposition and component structure → section 5 (Building Block
  View).** Section 4 names the *pattern*; section 5 shows the blocks.
- **How a concept actually works (persistence, security, logging) → section 8
  (Crosscutting Concepts).** Section 4 names the approach; section 8 details it.
  Source (Tip 4-1): detail belongs in section 8.
- **The full decision record with alternatives and consequences → section 9
  (Architecture Decisions).** Section 4 is the compact summary; a full ADR with
  options weighed lives in section 9.
- **The quality goals themselves → section 1 / section 10.** Section 4
  references goals to explain approaches; it does not define or prioritize them.

## Review rules

Severities derive from the arc42 source's own language. The template is advisory
throughout — *"Keep the explanations … short"*, *"is recommended"* — with no
RFC-2119 "must", so these are `SHOULD`, not `MUST`. The global
`HOUSE-CODEREF-1` rule in [`../CONVENTIONS.md`](../CONVENTIONS.md) also applies.

- **`A42-4-01` (SHOULD)** — The strategy is expressed compactly, as keywords or
  a short list of decisions, not as extended exposition.
  - *Check:* the chapter is a short list/table of decisions; flag long
    multi-paragraph designs or pasted configuration.
  - *Fail:* three pages of component walkthroughs and code.
  - *Pass:* a bulleted list of five cornerstone decisions, one to two sentences each.
  - *Source:* Form *"Keep the explanations of such key decisions short"*; Tip
    4-1 *"Explain your solution strategy in keywords, e.g. as a short list."*

- **`A42-4-02` (SHOULD)** — Each stated decision carries a rationale (the *why*),
  not just the choice.
  - *Check:* each decision entry includes a reason/motivation clause; flag bare
    technology names with no justification.
  - *Fail:* `- Uses PostgreSQL.`
  - *Pass:* `- PostgreSQL, for relational integrity across client/enrollment data.`
  - *Source:* Form *"Motivate what you have decided and why you decided that
    way"*; Tip 4-6 *"Explain **why** … The 'why' is often more important than
    the 'what' or 'how'."*

- **`A42-4-03` (SHOULD)** — The chapter addresses the fundamental decision
  categories that apply: technology, top-level decomposition, and approaches to
  the key quality goals.
  - *Check:* at least technology choices, a decomposition/pattern statement, and
    a quality-goal approach are present; flag a chapter that names only one.
  - *Source:* Contents *"technology decisions … the top-level decomposition …
    decisions on how to achieve key quality goals."*

- **`A42-4-04` (SHOULD)** — Solution approaches are tied to the key quality
  goals, ideally in a table mapping goal → scenario → approach → link to detail.
  - *Check:* each top quality goal from section 1 has a corresponding solution
    approach here; the recommended table has the four columns.
  - *Fail:* a technology list with no reference to any quality goal.
  - *Pass:* a row `Confidentiality | manager opens unassigned client | row-scoped policy | §8`.
  - *Source:* Tip 4-2 columns *"Quality goal · Scenario · Solution approach ·
    Link to Details"*; Tip 4-3 *"combine the documentation of quality-scenarios
    with the solution strategy."* (SHOULD, not MUST: the table is *"recommended."*)

- **`A42-4-05` (SHOULD)** — Details are deferred to the later chapters by
  reference, not restated here.
  - *Check:* where a decision needs elaboration, the chapter links to section 5
    (blocks) or section 8 (concepts) rather than reproducing the detail.
  - *Source:* Form *"Refer to details in the following sections"*; Tip 4-1
    detail explanations *"belong in section 8."*

## Sources

- **Canonical chapter (authoritative for content and that there are no official
  subsections):** `04_solution_strategy.adoc`, arc42-template 9.0-EN, git SHA
  `8dff0d9b`, read locally from
  `/tmp/arc42-template/EN/adoc/04_solution_strategy.adoc`. Cite by raw URL —
  <https://raw.githubusercontent.com/arc42/arc42-template/master/EN/adoc/04_solution_strategy.adoc>.
  Retrieved 2026-08-23.
- **Section page (Contents, Motivation, Form):**
  <https://docs.arc42.org/section-4/>. Retrieved 2026-08-23.
- **Tips fetched** (checkable review criteria only): 4-1 (keywords/compact),
  4-2 (quality-goal table columns), 4-3 (combine with quality scenarios), 4-6
  (justify the *why*). Each at `https://docs.arc42.org/tips/4-<n>/`, retrieved
  2026-08-23.
- **Tips skipped** (authoring advice, not a separate mechanical criterion — a
  later pass may revisit): 4-4 (refer to concepts/views/code — subsumed by the
  table's link column in `A42-4-04` and by `A42-4-05`), 4-5 (let the strategy
  grow iteratively — process advice, no reviewable criterion).
- **License:** arc42 template CC BY-SA 4.0; attribution in
  [`../00-index.md`](../00-index.md).
