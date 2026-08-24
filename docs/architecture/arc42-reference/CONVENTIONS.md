# arc42 reference — shared conventions (S0, frozen)

Frozen by S0 (app-jx2.1). Every `sections/NN-<slug>.md` and `00-index.md` copies
from here. Do not re-derive these; do not renumber IDs. Later sessions read this
file rather than guessing.

Upstream pinned: arc42-template **9.0-EN**, revdate July 2025, git SHA
`8dff0d9b1f9640684df8c3bbcdc2ee45f989ca0f`. Chapters cited by raw URL
`https://raw.githubusercontent.com/arc42/arc42-template/master/EN/adoc/<file>`.

## Canonical chapter filenames

Section titles match the template as published (the review skill matches headings
against our own documents). Output lives in `docs/architecture/arc42-reference/`.

| N  | source file (upstream)             | our file                                  | title                          |
|----|------------------------------------|-------------------------------------------|--------------------------------|
| 01 | `01_introduction_and_goals.adoc`   | `sections/01-introduction-and-goals.md`   | Introduction and Goals         |
| 02 | `02_architecture_constraints.adoc` | `sections/02-constraints.md`              | Constraints                    |
| 03 | `03_context_and_scope.adoc`        | `sections/03-context-and-scope.md`        | Context and Scope              |
| 04 | `04_solution_strategy.adoc`        | `sections/04-solution-strategy.md`        | Solution Strategy              |
| 05 | `05_building_block_view.adoc`      | `sections/05-building-block-view.md`      | Building Block View            |
| 06 | `06_runtime_view.adoc`             | `sections/06-runtime-view.md`             | Runtime View                   |
| 07 | `07_deployment_view.adoc`          | `sections/07-deployment-view.md`          | Deployment View                |
| 08 | `08_concepts.adoc`                 | `sections/08-crosscutting-concepts.md`    | Crosscutting Concepts          |
| 09 | `09_architecture_decisions.adoc`   | `sections/09-architecture-decisions.md`   | Architecture Decisions         |
| 10 | `10_quality_requirements.adoc`     | `sections/10-quality-requirements.md`     | Quality Requirements           |
| 11 | `11_technical_risks.adoc`          | `sections/11-risks-and-technical-debt.md` | Risks and Technical Debt       |
| 12 | `12_glossary.adoc`                 | `sections/12-glossary.md`                 | Glossary                       |

Filename mismatches to carry forward — the upstream basename does **not** match
our slug for these three:
- section 02 source is `02_architecture_constraints.adoc`
- section 08 source is `08_concepts.adoc`
- section 11 source is `11_technical_risks.adoc`

## Chapter template (nine headings, verbatim)

Every `sections/NN-<slug>.md` uses exactly these nine `##` headings, in this
order, with these names:

```
# NN. <Title>

## Purpose
## What belongs here
## Form & notation
## How much is enough
## Example
## Common mistakes
## Belongs elsewhere
## Review rules
## Sources
```

- **Purpose** — why this chapter exists, what question it answers for a reviewer.
- **What belongs here** — the content arc42 places in this chapter.
- **Form & notation** — tables, diagrams, prose; notations arc42 suggests.
- **How much is enough** — the stop condition; when a chapter is complete vs. bloated.
- **Example** — a worked fragment (see the example system sketched in `00-index.md`).
- **Common mistakes** — deviations to flag when reviewing an existing document.
- **Belongs elsewhere** — content reviewers mistakenly put here that goes in another chapter.
- **Review rules** — the machine-readable rule block (see rule conventions below).
- **Sources** — primary-source URLs with retrieval dates for every normative claim.

## Rule conventions (Review rules block)

- **ID scheme:** `A42-<N>-<seq>` where `<N>` is the chapter number and `<seq>` is
  a zero-padded sequence within the chapter (e.g. `A42-3-01`). IDs are **stable**:
  deprecate a rule, never renumber it. A retired rule keeps its ID and is marked
  deprecated.
- **Severity:** `MUST` / `SHOULD` / `MAY`, derived from the source's own language.
  Quote the justifying phrase from the source alongside the rule. Do not upgrade
  or invent severity the source does not support.
- **Mechanical check:** every rule carries a check a reviewer can verify by reading
  a document — concrete and falsifiable, not a judgement call.
- **House preferences:** use the `HOUSE-*` prefix, never `A42-*`. `A42-*` is
  reserved for rules traceable to the arc42 source.

Decided house rule:

- **`HOUSE-CODEREF-1` (SHOULD):** code references identify a class and method,
  never a file line number. Mechanical check: no rule or example cites `file:line`;
  references name a class and method instead. Rationale: line numbers rot on the
  next commit.

## Attribution block (for 00-index.md)

Drafted in S0; placed in `00-index.md` by app-jx2.2. Text:

> ## Attribution and license
>
> This reference is a derivative work based on the **arc42 template** (version
> 9.0-EN, July 2025), created, maintained, and © by Dr. Gernot Starke, Dr. Peter
> Hruschka, and contributors — see [arc42.org](https://arc42.org).
>
> The arc42 template and documentation are licensed under the
> [Creative Commons Attribution-ShareAlike 4.0 International License (CC BY-SA 4.0)](https://creativecommons.org/licenses/by-sa/4.0/).
> Because this document quotes and paraphrases the template, it is a derivative
> under that license and is itself released under **CC BY-SA 4.0**. Changes were
> made: the material has been rewritten, reorganized into a review-oriented
> reference, and extended with machine-readable review rules.

## License confirmation

`/tmp/arc42-template/LICENSE.txt` line 1 states: "The arc42 template and
documentation is licensed under the Creative Commons Attribution-ShareAlike 4.0
International License." Matches the website. Confirmed — our derivative inherits
the ShareAlike obligation and must carry the attribution block above.
