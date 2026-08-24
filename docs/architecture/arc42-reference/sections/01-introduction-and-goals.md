# 01. Introduction and Goals

## Purpose

This chapter answers one question for a reviewer: **do we know what this system
must do and what "good" means for it, and does everyone who matters agree?** It
captures the requirements and driving forces the architecture has to satisfy —
the essential features, the top quality goals, and the stakeholders whose
expectations shape every later decision. If the quality goals here are vague or
missing, every downstream chapter (solution strategy, quality requirements) has
nothing to trace back to.

## What belongs here

arc42 splits this chapter into three official subsections:

- **Requirements Overview** — a short description of the functional
  requirements and driving forces: essential features and functional
  requirements, ideally linking to a fuller requirements document rather than
  restating it. *"Short description of the functional requirements, driving
  forces, extract (or abstract) of requirements."*
- **Quality Goals** — the top three to five quality goals for the
  **architecture** (not the project), each tied to a concrete scenario and
  ordered by priority. *"The top three (max five) quality goals for the
  architecture whose fulfillment is of highest importance to the major
  stakeholders."*
- **Stakeholders** — an explicit table of the roles, people, and organizations
  that must know, approve, work with, or depend on the architecture, together
  with what each expects from it.

## Form & notation

- **Requirements Overview** — short prose, or a tabular use-case format. Link
  to existing requirements documents (with version and location) instead of
  copying them.
- **Quality Goals** — a table of quality goals paired with concrete scenarios,
  ordered by priority. A quality scenario states how the system should react to
  a given event ("selects the necessary data within 1 second for up to 100
  concurrent users"), not a bare adjective.
- **Stakeholders** — a table with role/name, contact, and expectations. The
  upstream template ships this exact three-column skeleton (Role/Name, Contact,
  Expectations).

## How much is enough

This is an *overview*, not a specification. Keep the requirements excerpt as
short as the reader can still follow; balance readability against redundancy
with any real requirements document. Three quality goals is the target and five
is the ceiling — a longer list means detail that belongs in section 10, not
here. A lean section 1 with three well-scoped quality scenarios and a short
stakeholder table is **complete**, not deficient; do not flag it for brevity.

## Example

A good section 1 for **RosterRail** (see the example system in
[`../00-index.md`](../00-index.md)):

> ### Requirements Overview
>
> RosterRail lets a housing agency intake clients, assign them to case managers,
> and track program enrollments. Essential features: client intake, case-manager
> assignment, enrollment tracking across programs, and a nightly enrollment
> extract to the downstream HMIS warehouse. Full functional requirements live in
> the product backlog (Jira project `RR`, epic `RR-100`); this overview
> summarizes only the driving features.
>
> ### Quality Goals
>
> | Priority | Quality goal   | Scenario                                                                                             |
> |----------|----------------|------------------------------------------------------------------------------------------------------|
> | 1        | Confidentiality | A case manager requests a client record they are not assigned to; the system denies access and logs the attempt. |
> | 2        | Reliability    | The nightly HMIS extract fails mid-run; on the next run it resends the full day's records with no duplicates in the warehouse. |
> | 3        | Usability      | A new case manager completes a client intake without training in under 5 minutes.                    |
>
> ### Stakeholders
>
> | Role/Name          | Contact        | Expectations                                                              |
> |--------------------|----------------|---------------------------------------------------------------------------|
> | Case manager       | _(operations)_ | Fast intake; only sees clients assigned to them.                          |
> | Agency director    | _(sponsor)_    | Reliable enrollment reporting to funders.                                 |
> | HMIS warehouse team | _(external)_  | Stable extract format and schedule; clear contact on failures.            |

Three quality goals, each a scenario rather than a keyword; a stakeholder table
with expectations. That is enough.

## Common mistakes

- **Project goals dressed as quality goals.** "Ship by Q3" or "stay under
  budget" are project goals; arc42 wants goals *for the architecture*. Source:
  *"We really mean quality goals for the architecture. Don't confuse them with
  project goals."*
- **Buzzword quality goals.** "Fast", "secure", "scalable" with no scenario are
  unreviewable. Source: *"Make sure to be very concrete about these qualities,
  avoid buzzwords."*
- **More than five quality goals.** A list of a dozen means the important ones
  are not prioritized.
- **A full functional spec instead of an overview.** Copying the whole
  requirements document here duplicates it and rots.

## Belongs elsewhere

- **Detailed, complete quality requirements → section 10 (Quality
  Requirements).** Section 1 carries only the handful of top goals. Source (Tip
  1-18): *"Describe the complete detailed quality requirements in arc42 section
  10. Section 1 (here) shall only contain a handful of the most important or
  critical of such requirements."*
- **Constraints (technical, organizational, conventions) → section 2.** A fixed
  technology or mandated standard is a constraint, not a goal.
- **System scope and external interfaces → section 3 (Context and Scope).** Who
  the system talks to belongs in context; section 1 names stakeholders, not
  interface contracts.

## Review rules

Severities derive from the arc42 source's own language. The template is advisory
throughout — it uses descriptive phrasing ("a table with…", "the top three")
rather than RFC-2119 "must" — so these are `SHOULD`, not `MUST`. The global
`HOUSE-CODEREF-1` rule in [`../CONVENTIONS.md`](../CONVENTIONS.md) also applies.

- **`A42-1-01` (SHOULD)** — The chapter contains the three arc42 subsections:
  *Requirements Overview*, *Quality Goals*, and *Stakeholders*.
  - *Check:* three subsection headings are present matching those titles (or
    obvious synonyms, e.g. "Stakeholder").
  - *Source:* the upstream chapter is structured as exactly these three `===`
    subsections —
    <https://raw.githubusercontent.com/arc42/arc42-template/master/EN/adoc/01_introduction_and_goals.adoc>.

- **`A42-1-02` (SHOULD)** — Quality Goals lists no more than five goals.
  - *Check:* count the quality goals (table rows or list items); flag if more
    than five.
  - *Source:* *"The top three (max five) quality goals"*; Tip 1-16 *"describe
    only a handful (top 3-5) of these requirements."*

- **`A42-1-03` (SHOULD)** — Each quality goal is expressed as a concrete
  scenario, not a bare keyword.
  - *Check:* each quality goal has an accompanying sentence describing a
    situation and the system's expected reaction; flag single-adjective goals.
  - *Fail:* `| 1 | Performance |` — a keyword with no scenario.
  - *Pass:* `| 1 | Performance | Search returns results within 1s for up to 100 concurrent users. |`
  - *Source:* Form *"A table with quality goals and concrete scenarios"*;
    *"avoid buzzwords"*; Tip 1-12 *"Quality scenarios explain in short sentences
    how the system should react in certain situations at certain events."*

- **`A42-1-04` (SHOULD)** — Stakeholders are given as a table that includes each
  stakeholder's expectations.
  - *Check:* the Stakeholders subsection contains a table with a role column and
    an expectations column populated for each row.
  - *Fail:* a bullet list of role names with no expectations.
  - *Pass:* a table with `Role/Name | Contact | Expectations` rows filled in.
  - *Source:* Form *"Table with role names, person names, and their expectations
    with respect to the architecture and its documentation"*; Tip 1-21 *"in the
    form of a table"*; Tip 1-20 (expectations).

## Sources

- **Canonical chapter (authoritative for subsection structure and numbering):**
  `01_introduction_and_goals.adoc`, arc42-template 9.0-EN, git SHA `8dff0d9b`,
  read locally from `/tmp/arc42-template/EN/adoc/01_introduction_and_goals.adoc`.
  Cite by raw URL —
  <https://raw.githubusercontent.com/arc42/arc42-template/master/EN/adoc/01_introduction_and_goals.adoc>.
  Retrieved 2026-08-23.
- **Section page (Contents, Motivation, Form):**
  <https://docs.arc42.org/section-1/>. Retrieved 2026-08-23.
- **Tips fetched** (checkable review criteria only): 1-12 (scenarios), 1-16 (top
  3-5 quality goals), 1-18 (defer detail to section 10), 1-20 (stakeholder
  expectations), 1-21 (stakeholder table). All <https://docs.arc42.org/tips/>,
  retrieved 2026-08-23.
- **Tips skipped** (authoring advice, not review criteria — a later pass may
  revisit): 1-1, 1-3, 1-4, 1-5, 1-6, 1-7, 1-8, 1-9, 1-10, 1-11, 1-13, 1-14,
  1-15, 1-17, 1-19, 1-22, 1-23, 1-24. Tip 1-2 (limit to essential use cases)
  informs *How much is enough* but yields no separate mechanical rule.
- **License:** arc42 template CC BY-SA 4.0; attribution in
  [`../00-index.md`](../00-index.md).
