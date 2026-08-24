# 02. Constraints

## Purpose

This chapter answers one question for a reviewer: **where were the architects
_not_ free, and does everyone know it?** It records the requirements that limit
design and implementation freedom — mandated technologies, organizational and
political rules, and conventions the team must follow. Its value is boundary
setting: a decision in a later chapter (solution strategy, building blocks) that
looks arbitrary is often forced by a constraint recorded here, and a constraint
that is missing here is one a reviewer cannot tell apart from a free choice.

## What belongs here

arc42 does not split this chapter into fixed numbered subsections. It offers
**optional** categories to group constraints when there are enough of them to
warrant it:

- **Technical constraints** — mandated hardware, operations, technology, product,
  framework, or reference-architecture choices imposed on the team.
- **Organizational and political constraints** — time, budget, staffing, process,
  contracting, and legal requirements imposed from outside the architecture.
- **Conventions** — programming, versioning, documentation, and naming standards
  the team must adhere to.

The defining test for every entry: it must be *"[a]ny requirement that
constrains software architects in their freedom of design and implementation
decisions or decision about the development process."* A freely made design
decision is not a constraint — it belongs in section 4 or 9.

## Form & notation

- **A table of constraints with explanations** is the arc42 form: *"Simple tables
  of constraints with explanations."* Each row names the constraint and explains
  what it forces or rules out.
- **Optional subdivision into categories** (technical / organizational and
  political / conventions), used only when the number and mix of constraints make
  grouping useful: *"If needed you can subdivide them into…"*

## How much is enough

This is a boundary list, not an essay. Record the constraints that actually bind
the architecture, each with a one-line explanation of its effect; stop there. A
short, single, un-subdivided table is **complete**, not deficient — do not flag a
lean section 2 for brevity, and do not flag the absence of category headings when
there are only a handful of constraints. If there are genuinely no external
constraints, an explicit *"none identified"* is a valid section, not a gap.

## Example

A good section 2 for **RosterRail** (see the example system in
[`../00-index.md`](../00-index.md)):

> RosterRail's architects must work within these constraints.
>
> **Technical**
>
> | Constraint | Explanation |
> |------------|-------------|
> | Ruby on Rails + PostgreSQL | Mandated by the agency's platform team; all services run on the existing Rails/PostgreSQL stack, no alternative datastore. |
> | Staff authenticate via the agency SSO | No local password store; the app must delegate authentication to the existing SSO provider. |
>
> **Organizational and political**
>
> | Constraint | Explanation |
> |------------|-------------|
> | Nightly HMIS extract in HUD CSV format | The downstream warehouse dictates the file format and schedule; RosterRail cannot change either. |
> | Go-live before the funder's fiscal year end | Fixed external deadline; limits how much can be built for the first release. |
>
> **Conventions**
>
> | Constraint | Explanation |
> |------------|-------------|
> | Team Ruby style guide + RuboCop | All code passes the shared linter configuration before merge. |

A table per category, each row explaining what the constraint forces. That is
enough; the categories appear only because the constraints genuinely span all
three.

## Common mistakes

- **Design decisions dressed as constraints.** "We use service objects" or "we
  cache with Redis" are choices the team made freely; unless something *imposed*
  them, they belong in section 4 (Solution Strategy) or 9 (Architecture
  Decisions). arc42 scopes this chapter to *"requirement[s] that constrain…
  freedom of design."*
- **Quality goals filed as constraints.** "Must be highly available" is a quality
  goal (section 1/10), not an externally imposed limit on design freedom.
- **Constraints named without their effect.** A bare list ("Java 17", "AWS") with
  no explanation of what it forces is not reviewable; arc42 asks for tables *"with
  explanations."*
- **Over-structuring a short list.** Splitting four constraints across three
  labelled category tables is padding; subdivision is *"if needed"*, not mandatory.

## Belongs elsewhere

- **Freely chosen technology and patterns → section 4 (Solution Strategy) / 9
  (Architecture Decisions).** Section 2 holds only what was *imposed* on the team,
  not what the team decided.
- **Quality goals and quality scenarios → section 1 (top goals) and section 10
  (detailed quality requirements).** A required quality level is a goal, not a
  constraint.
- **The consequences and trade-offs of a constraint, worked through → section 9
  (Architecture Decisions) / 11 (Risks and Technical Debt).** Section 2 names the
  constraint and its immediate effect; the reasoning and fallout of living with it
  are recorded where decisions and risks live. (Tip 2-2 advises clarifying
  consequences and negotiating unreasonable ones — an authoring activity, not
  content this chapter must carry in full.)

## Review rules

Severities derive from the arc42 source's own language. The template is advisory
here — it describes the form (*"Simple tables of constraints with explanations"*)
and marks subdivision as optional (*"If needed"*) rather than using RFC-2119
"must" — so the structural rule is `SHOULD` and the subdivision rule is `MAY`. The
global `HOUSE-CODEREF-1` rule in [`../CONVENTIONS.md`](../CONVENTIONS.md) also
applies.

- **`A42-2-01` (SHOULD)** — Constraints are presented as a table (or tables) in
  which each constraint carries an explanation, not as a bare list of terms.
  - *Check:* the section contains a table with one column naming each constraint
    and a populated explanation/description for every row; flag a bulleted list of
    names with no explanations.
  - *Fail:* `- Ruby on Rails` `- AWS` `- SSO` (names, no explanations).
  - *Pass:* `| Ruby on Rails + PostgreSQL | Mandated platform stack; no alternative datastore. |`
  - *Source:* Form *"Simple tables of constraints with explanations."*
    <https://raw.githubusercontent.com/arc42/arc42-template/master/EN/adoc/02_architecture_constraints.adoc>.

- **`A42-2-02` (MAY)** — When the constraints span more than one kind, they are
  grouped into labelled categories (technical / organizational and political /
  conventions).
  - *Check:* if entries clearly mix categories (e.g. a mandated framework
    alongside a budget deadline), there are category groupings or headings; do
    **not** flag the absence of categories when there are only a few constraints or
    they are all of one kind.
  - *Source:* Form *"If needed you can subdivide them into technical constraints,
    organizational and political constraints and conventions"*; Tip 2-5 *"If
    necessary, differentiate between technical, organizational and political
    constraints or overlapping conventions."* Optional wording ("If needed" / "If
    necessary") fixes this at `MAY`.

## Sources

- **Canonical chapter (authoritative for structure and the optional categories):**
  `02_architecture_constraints.adoc`, arc42-template 9.0-EN, git SHA `8dff0d9b`,
  read locally from
  `/tmp/arc42-template/EN/adoc/02_architecture_constraints.adoc`. Cite by raw URL —
  <https://raw.githubusercontent.com/arc42/arc42-template/master/EN/adoc/02_architecture_constraints.adoc>.
  Retrieved 2026-08-23. (Provides Contents, Motivation, and Form; the chapter
  defines no numbered subsections.)
- **Section page (Contents, Motivation, Form):**
  <https://docs.arc42.org/section-2/>. Retrieved 2026-08-23.
- **Tips fetched** (checkable review criteria only): 2-5 (differentiate constraint
  categories — supports `A42-2-02`). <https://docs.arc42.org/tips/2-5/>, retrieved
  2026-08-23.
- **Tips read but not turned into a rule** (authoring advice, informs prose only —
  a later pass may revisit): 2-1 (look at other systems to find constraints), 2-2
  (clarify consequences; negotiate unreasonable constraints — informs *Belongs
  elsewhere*), 2-3 (disclose organizational constraints), 2-4 (disclose technical
  constraints). All under <https://docs.arc42.org/tips/>, retrieved 2026-08-23.
  The tip list for section 2 ends at 2-5 (2-6 returns 404).
- **License:** arc42 template CC BY-SA 4.0; attribution in
  [`../00-index.md`](../00-index.md).
