# 11. Risks and Technical Debt

## Purpose

This chapter answers one question for a reviewer: **have we written down the
things most likely to hurt us, in priority order, so management can act on
them?** It is the architecture's honest ledger of known risks and accumulated
technical debt. A document that omits it is not risk-free; it is silent about
risk, which is worse.

## What belongs here

arc42 gives this chapter no numbered subsections — it is a single prioritized
list. Two kinds of entry belong:

- **Technical risks** — things that *might* go wrong (an unproven dependency, a
  scaling unknown, a single point of failure), ideally each with a suggested
  measure to minimize, mitigate, or avoid it. Source: Contents *"A list of
  identified technical risks or technical debts, ordered by priority."*
- **Technical debt** — shortcuts and known-suboptimal solutions already in the
  system, ideally each with a suggested measure to reduce it. Source: Form
  *"List of risks and/or technical debts, probably including suggested measures
  to minimize, mitigate or avoid risks or reduce technical debts."*

## Form & notation

A prioritized list or table. A useful shape is one row per risk/debt with
columns for priority, the risk or debt, and a suggested measure; probability and
impact columns are optional refinements. Order by priority so the reader sees
the worst first. Source: Contents *"ordered by priority"*; Form *"List of risks
and/or technical debts, probably including suggested measures."*

## How much is enough

A short prioritized list of the genuinely significant risks and debts is
**complete**. This chapter is deliberately thin: it is a ledger, not an analysis
report. Do not flag a lean section 11 for brevity — one honest table of the top
handful of items beats a padded catalogue. Zero entries is a smell (few real
systems have none), but a small list is not a defect. Mitigation columns are
encouraged, not mandatory (arc42 says *"probably including"*).

## Example

A good section 11 for **RosterRail** (see the example system in
[`../00-index.md`](../00-index.md)):

> | Priority | Risk / debt                                                                 | Suggested measure                                                                 |
> |----------|-----------------------------------------------------------------------------|-----------------------------------------------------------------------------------|
> | 1        | *(Risk)* SSO provider is a single point of failure; an outage locks out all staff. | Add a break-glass local login for admins; alert on SSO health.                    |
> | 2        | *(Debt)* The nightly HMIS extract has no automated reconciliation; silent drops go unnoticed. | Add a record-count reconciliation step comparing sent vs. acknowledged rows.      |
> | 3        | *(Debt)* Enrollment de-duplication logic lives in `EnrollmentExtract#dedupe` with no test coverage. | Backfill characterization tests before the next change to the extract.            |

Three prioritized entries, each naming a concrete measure, risks and debt
distinguished. That is enough.

## Common mistakes

- **Prose instead of a prioritized list.** A narrative paragraph about "some
  concerns" cannot be scanned or acted on; arc42 asks for a list *ordered by
  priority*.
- **Risks with no owner-actionable measure.** A risk stated with no suggested
  mitigation leaves the reader nowhere to go (encouraged, not required).
- **Confusing risk with decision.** "We chose PostgreSQL" is a decision
  (section 9); "PostgreSQL row-level locking may not scale past N writers" is a
  risk.
- **Debt hidden behind file line numbers.** Technical debt entries that cite
  `file:line` rot on the next commit; name the class and method instead
  (`HOUSE-CODEREF-1`).

## Belongs elsewhere

- **Detailed quality requirements and scenarios → section 10 (Quality
  Requirements).** A quality scenario states desired behaviour; a risk states
  what threatens it. The scenario belongs in 10; only the threat belongs here.
- **Architecture decisions and their rationale → section 9 (Architecture
  Decisions).** A made decision is not a risk. If a decision carries a risk,
  the decision goes in 9 and the residual risk is listed here.
- **Fixed constraints → section 2 (Constraints).** A mandated technology is a
  constraint, not a risk — unless it introduces a specific, articulated threat.

## Review rules

Severities derive from the arc42 source's own language. The template is advisory
and describes the section as *"a list … ordered by priority"* with measures
*"probably included"* — descriptive, not RFC-2119 "must" — so these are
`SHOULD`/`MAY`, not `MUST`. The global `HOUSE-CODEREF-1` rule in
[`../CONVENTIONS.md`](../CONVENTIONS.md) also applies.

- **`A42-11-01` (SHOULD)** — The section presents risks and/or technical debt as
  a list (table or bullets), not as running prose.
  - *Check:* the chapter body is a list/table of discrete entries; flag a chapter
    that is only narrative paragraphs.
  - *Fail:* "There are a few concerns around scaling and the extract job."
  - *Pass:* a table (or bullet list) with one row per named risk/debt.
  - *Source:* Contents *"A list of identified technical risks or technical debts"*
    — <https://raw.githubusercontent.com/arc42/arc42-template/master/EN/adoc/11_technical_risks.adoc>.

- **`A42-11-02` (SHOULD)** — The list is ordered by priority.
  - *Check:* entries carry an explicit priority/severity ordering (a priority
    column, or an ordering the text names as by-priority); flag an unordered dump.
  - *Fail:* an alphabetical or arbitrary list with no priority signal.
  - *Pass:* a `Priority` column, or "ordered most- to least-critical" stated.
  - *Source:* Contents *"ordered by priority"* — same URL as A42-11-01.

- **`A42-11-03` (MAY)** — Each risk or debt names a suggested measure to
  mitigate/avoid the risk or reduce the debt.
  - *Check:* each entry has an associated measure/mitigation; absence is a
    weakness to note, not a failure (arc42 says *"probably including"*).
  - *Fail:* a risk row with an empty or missing measure column.
  - *Pass:* every row pairs the risk/debt with a concrete suggested measure.
  - *Source:* Form *"probably including suggested measures to minimize, mitigate
    or avoid risks or reduce technical debts"* — same URL as A42-11-01. The
    hedge *"probably"* is why this is `MAY`, not `SHOULD`.

## Sources

- **Canonical chapter (authoritative for content and form):**
  `11_technical_risks.adoc`, arc42-template 9.0-EN, git SHA `8dff0d9b`, read
  locally from `/tmp/arc42-template/EN/adoc/11_technical_risks.adoc`. Cite by
  raw URL —
  <https://raw.githubusercontent.com/arc42/arc42-template/master/EN/adoc/11_technical_risks.adoc>.
  Retrieved 2026-08-23. (Upstream heading reads "Risks and Technical Debts";
  our canonical title follows the published section title "Risks and Technical
  Debt".)
- **Section page (Content, Motivation, Form):**
  <https://docs.arc42.org/section-11/>. Retrieved 2026-08-23.
- **Tips skipped** (all authoring/discovery techniques — how to *find* risks, not
  checkable criteria for a written document; a later pass may revisit): 11-1
  (ask different stakeholders), 11-2 (analyze external interfaces), 11-3
  (qualitative evaluation against requirements), 11-4 (analyze processes), 11-5
  (analyze data structures), 11-6 (analyze source code). Verified 11-3 and 11-6
  by fetching them; both advise discovery methods and yield no mechanical review
  rule. All <https://docs.arc42.org/section-11/>, retrieved 2026-08-23.
- **License:** arc42 template CC BY-SA 4.0; attribution in
  [`../00-index.md`](../00-index.md).
