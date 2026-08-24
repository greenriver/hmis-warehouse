# arc42 reference (template v9.0-EN)

A markdown reference for the arc42 template, built for one job: **help us review
and write our own architecture documentation.** Given our section 3, find gaps
and deviations; given a blank section 3, help structure it. A Claude skill
consumes this reference to do the review, so each chapter carries a
machine-readable rule block alongside its prose.

Shared conventions — chapter filenames, the nine-heading chapter template, and
the rule ID/severity scheme — are frozen in [`CONVENTIONS.md`](CONVENTIONS.md).
Every chapter copies from there.

## Map

| N  | chapter                                                             | title                    |
|----|---------------------------------------------------------------------|--------------------------|
| 01 | [`sections/01-introduction-and-goals.md`](sections/01-introduction-and-goals.md) | Introduction and Goals   |
| 02 | [`sections/02-constraints.md`](sections/02-constraints.md)          | Constraints              |
| 03 | [`sections/03-context-and-scope.md`](sections/03-context-and-scope.md) | Context and Scope        |
| 04 | [`sections/04-solution-strategy.md`](sections/04-solution-strategy.md) | Solution Strategy        |
| 05 | [`sections/05-building-block-view.md`](sections/05-building-block-view.md) | Building Block View      |
| 06 | [`sections/06-runtime-view.md`](sections/06-runtime-view.md)        | Runtime View             |
| 07 | [`sections/07-deployment-view.md`](sections/07-deployment-view.md)  | Deployment View          |
| 08 | [`sections/08-crosscutting-concepts.md`](sections/08-crosscutting-concepts.md) | Crosscutting Concepts    |
| 09 | [`sections/09-architecture-decisions.md`](sections/09-architecture-decisions.md) | Architecture Decisions   |
| 10 | [`sections/10-quality-requirements.md`](sections/10-quality-requirements.md) | Quality Requirements     |
| 11 | [`sections/11-risks-and-technical-debt.md`](sections/11-risks-and-technical-debt.md) | Risks and Technical Debt |
| 12 | [`sections/12-glossary.md`](sections/12-glossary.md)                | Glossary                 |

## Quality model dataset

[`quality-model/`](quality-model/) holds a generated extract of the **Q42 quality
model** ([quality.arc42.org](https://quality.arc42.org)), pinned to
`arc42/quality.arc42.org-site` @ `3a24a3c640a7bb32fb3d5344dcc7dcda8d6e22f0`,
retrieved 2026-08-24. Refresh by diffing that SHA against `HEAD` and
regenerating; each file repeats its own provenance header.

| File | Holds | Consult it when |
|------|-------|-----------------|
| [`qualities.md`](quality-model/qualities.md) | 191 quality characteristics, each with its dimension tags, related characteristics, and governing standards | Checking that a document's quality labels are real dimensions, or finding the canonical name for a quality we invented a label for |
| [`requirements.md`](quality-model/requirements.md) | 149 example quality scenarios in Context / Trigger / Response / Acceptance Criteria form | Writing or reviewing a section 10 scenario — these are templates to adapt, not a checklist |
| [`approaches.md`](quality-model/approaches.md) | 55 solution approaches (tactics and patterns), indexed by the quality each enables, with the qualities each one costs | Reviewing section 4 or 8: naming a pattern we already use, or finding the trade-off we failed to record |
| [`standards.md`](quality-model/standards.md) | 46 standards across 13 categories | Checking whether a constraint or compliance obligation has a named standard behind it |

The nine dimension tags are `reliable`, `usable`, `suitable`, `safe`, `flexible`,
`secure`, `efficient`, `maintainable`, `operable`. A label outside that set is not
a dimension, whatever else it may be — that check is the dataset's most direct use
against a section 10.

## How to use

For a human writing or reviewing a document, read a chapter's prose top to
bottom: **Purpose** and **What belongs here** say what the chapter is for,
**Form & notation** and **How much is enough** calibrate depth, and **Common
mistakes** and **Belongs elsewhere** are the deviation checklist. **Example**
shows a worked fragment against the system sketched below.

For the review skill, the **Review rules** block in each chapter is the
machine-readable contract. Each rule has a stable ID (`A42-<N>-<seq>` for
arc42-sourced rules, `HOUSE-*` for our own preferences), a `MUST`/`SHOULD`/`MAY`
severity, and a mechanical check the skill applies to a target document. The
prose orients the human; the rule blocks drive the machine review. Match section
headings against the official titles in the Map — the titles are exact so the
skill can align our documents to chapters.

## Example system

**RosterRail** is a fictional Ruby on Rails / PostgreSQL / React application that
lets a housing agency intake clients, assign them to case managers, and track
enrollments across programs. It authenticates staff through an external SSO
provider, persists everything in PostgreSQL, and pushes nightly enrollment
extracts to a downstream HMIS warehouse over a REST API.

*This sketch exists only so each chapter's Example refers to the same system. It
is deliberately not documented properly here; the worked examples live in the
chapters that use them.*

## Glossary of coined terms

Terms we coined for clarity, defined once, so later sessions reuse the name
instead of inventing a second one for the same thing. Append here as chapters
introduce terms; this may start empty.

*(none yet)*

## Attribution and license

This reference is a derivative work based on the **arc42 template** (version
9.0-EN, July 2025), created, maintained, and © by Dr. Gernot Starke, Dr. Peter
Hruschka, and contributors — see [arc42.org](https://arc42.org).

The arc42 template and documentation are licensed under the
[Creative Commons Attribution-ShareAlike 4.0 International License (CC BY-SA 4.0)](https://creativecommons.org/licenses/by-sa/4.0/).
Because this document quotes and paraphrases the template, it is a derivative
under that license and is itself released under **CC BY-SA 4.0**. Changes were
made: the material has been rewritten, reorganized into a review-oriented
reference, and extended with machine-readable review rules.
