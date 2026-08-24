# 12. Glossary

## Purpose

This chapter answers one question for a reviewer: **do all stakeholders share
one vocabulary for this system?** It is the single place where the important
domain and technical terms are defined, so that readers of every other chapter
resolve a term the same way and no two people use different words for the same
thing. For a reviewer it doubles as a consistency check: a term used
meaningfully across the document but absent here is a gap.

## What belongs here

The most important domain and technical terms stakeholders use when discussing
the system, each with a definition. arc42 defines **no numbered subsections**
for this chapter — it is a single table, not a set of `===` subsections. The
glossary also serves as a source for translations when the team works across
languages.

Source: *"The most important domain and technical terms that your stakeholders
use when discussing the system"*; *"You can also see the glossary as source for
translations if you work in multi-language teams."*

## Form & notation

A table with two columns, **Term** and **Definition**, with optional further
columns for translations. Tip 12-2 adds that the table should be
**alphabetically sorted**.

Source: Form *"A table with columns <Term> and <Definition>. Potentially more
columns in case you need translations."*; Tip 12-2 *"an alphabetically sorted
table of the most important terms."*

## How much is enough

Keep it compact — roughly 10–30 genuinely important terms. The glossary defines
the domain- and system-specific vocabulary; it is not an encyclopedia. A lean
table of the terms that actually recur in the document is **complete**, not
deficient; do not flag it for brevity. Conversely, common technical terms that
need no explanation (UML, Java, REST) are padding and should be left out.

Source: Tip 12-5 *"Keep the glossary compact! Avoid trivia"* — *"a small
glossary of 10-30 terms"*, *"You don't want to write another encyclopedia or
re-create wikipedia in your glossary!"*

## Example

A good section 12 for **RosterRail** (see the example system in
[`../00-index.md`](../00-index.md)):

> | Term            | Definition                                                                                     |
> |-----------------|------------------------------------------------------------------------------------------------|
> | Case manager    | Staff member responsible for a set of assigned clients; sees only clients assigned to them.    |
> | Client          | A person the agency intakes and serves; the subject of enrollments.                            |
> | Enrollment      | A client's participation in one program over a date range; the unit reported to the warehouse. |
> | HMIS warehouse  | The external downstream system that receives the nightly enrollment extract over REST.         |
> | Intake          | The process of registering a new client into RosterRail.                                       |

Alphabetically sorted, domain terms only, one definition each. That is enough.

## Common mistakes

- **Synonyms and homonyms left unresolved.** Two rows naming the same concept
  differently, or one term used with two meanings, defeat the chapter's purpose.
  Source: Motivation — stakeholders should *"not use synonyms and homonyms."*
- **Trivia and encyclopedia entries.** Defining well-known technical terms
  (UML, Java, REST) bloats the table without helping any stakeholder. Source:
  Tip 12-5 *"Avoid trivia"*.
- **Unsorted table.** An unordered list of terms is hard to scan. Source: Tip
  12-2 *"alphabetically sorted table."*

## Belongs elsewhere

- **Ubiquitous-language modelling and domain concepts explained at length →
  section 8 (Crosscutting Concepts).** The glossary names and defines a term in
  one line; a domain model or the reasoning behind a concept is a crosscutting
  concept. Source: Tip 12-2 notes the glossary *"may align with the 'ubiquitous
  language' concept from Domain-Driven Design, potentially fitting within
  arc42's section 8 on crosscutting concepts."*
- **A (graphical) domain model → section 8.** Tip 12-3 suggests amending the
  glossary with a model; the model itself is a crosscutting concept, while
  section 12 stays a term/definition table.

## Review rules

Severities derive from the arc42 source's own language. The template is advisory
throughout — it uses descriptive phrasing (*"a table with…"*, *"the most
important … terms"*) rather than RFC-2119 "must" — so these are `SHOULD`, not
`MUST`. The global `HOUSE-CODEREF-1` rule in
[`../CONVENTIONS.md`](../CONVENTIONS.md) also applies.

- **`A42-12-01` (SHOULD)** — The glossary is a table with at least a term column
  and a definition column.
  - *Check:* a table is present whose columns include a term and its definition;
    flag a bare bullet list of terms without definitions.
  - *Fail:* `- Enrollment` `- Intake` (terms, no definitions).
  - *Pass:* `| Enrollment | A client's participation in one program... |`
  - *Source:* Form *"A table with columns <Term> and <Definition>"* —
    <https://raw.githubusercontent.com/arc42/arc42-template/master/EN/adoc/12_glossary.adoc>.

- **`A42-12-02` (SHOULD)** — Terms are listed in alphabetical order.
  - *Check:* read the term column top to bottom; flag if not alphabetically
    ordered.
  - *Source:* Tip 12-2 *"an alphabetically sorted table of the most important
    terms."*

- **`A42-12-03` (SHOULD)** — No synonyms or homonyms: each concept has one term,
  each term one definition.
  - *Check:* no two rows define the same concept under different terms; no term
    appears twice with differing definitions.
  - *Fail:* rows `Client | ...` and `Participant | ...` defining the same person.
  - *Pass:* a single `Client` row, with `Participant` noted as a synonym in that
    definition if the word is also in use.
  - *Source:* Motivation — stakeholders *"do not use synonyms and homonyms."*

- **`A42-12-04` (SHOULD)** — The glossary is compact and free of trivia: entries
  are domain- or system-specific, not general technical terms needing no
  explanation.
  - *Check:* flag entries for widely understood technology (e.g. UML, Java,
    HTTP, REST) carrying only a generic definition; a table far outside ~10–30
    terms warrants a compactness look.
  - *Source:* Tip 12-5 *"Keep the glossary compact! Avoid trivia"*, *"a small
    glossary of 10-30 terms"*.

## Sources

- **Canonical chapter (authoritative for structure — a single Term/Definition
  table, no subsections):** `12_glossary.adoc`, arc42-template 9.0-EN, git SHA
  `8dff0d9b`, read locally from `/tmp/arc42-template/EN/adoc/12_glossary.adoc`.
  Cite by raw URL —
  <https://raw.githubusercontent.com/arc42/arc42-template/master/EN/adoc/12_glossary.adoc>.
  Retrieved 2026-08-23.
- **Section page (Contents, Motivation, Form):**
  <https://docs.arc42.org/section-12/>. Retrieved 2026-08-23.
- **Tips fetched** (checkable review criteria only): 12-2 (alphabetically sorted
  table) <https://docs.arc42.org/tips/12-2/>; 12-5 (keep compact, avoid trivia)
  <https://docs.arc42.org/tips/12-5/>. Both retrieved 2026-08-23.
- **Tips skipped** (authoring/organizational advice, not document review
  criteria — a later pass may revisit): 12-1 (take the glossary seriously),
  12-3 (amend with a graphical model — informs *Belongs elsewhere*, no separate
  mechanical rule), 12-4 (include translations — conditional on multi-language
  teams, no general rule), 12-6 (make the product owner responsible — an
  ownership practice, not checkable in the document). Tip titles read from the
  section-12 page; the tips index page <https://docs.arc42.org/tips/12/>
  returned 404 on 2026-08-23.
- **License:** arc42 template CC BY-SA 4.0; attribution in
  [`../00-index.md`](../00-index.md).
