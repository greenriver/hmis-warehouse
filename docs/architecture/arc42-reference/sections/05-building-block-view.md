# 05. Building Block View

## Purpose

This chapter answers one question for a reviewer: **can you see how the system
is put together — its static decomposition into parts and the dependencies
between them — without reading the source?** It is the *floor plan* of the
architecture: a hierarchy of boxes that starts with the whole system and zooms
in only where zooming in earns its keep. arc42 calls this view **mandatory** for
every architecture documentation, so its absence is not a matter of taste. If
this chapter is missing or stops at a single undifferentiated blob, a reviewer
has no map to check any other structural claim against.

## What belongs here

The building block view is a **hierarchy of black boxes and white boxes**. A
*white box* is opened up — you see the parts inside and why they are arranged
that way; a *black box* is described only by what it is responsible for and how
you talk to it, not by its internals.

- **Level 1 — whitebox of the overall system.** The white-box description of the
  whole system: an overview diagram, a motivation for the decomposition, and a
  black-box description of every contained building block. *"Level 1 is the
  white box description of the overall system together with black box
  descriptions of all contained building blocks."*
- **Level 2, 3, … — selected refinements.** Each lower level opens up *some*
  building block from the level above as a white box, exposing its own contained
  black boxes. Refinement is deliberately partial — you open only the blocks
  worth opening.

Two templates carry the content:

- **Black-box description** — for each contained block: its
  **purpose/responsibility**, its **interface(s)**, and optionally
  quality/performance characteristics, directory/file location, fulfilled
  requirements, and open issues/risks. A pragmatic overview may collapse this to
  a single table of **name and responsibility**.
- **White-box description** — for each opened block: an **overview diagram**, a
  **motivation** for that decomposition, black-box descriptions of the parts
  inside, and optionally the important internal interfaces.

## Form & notation

- **Diagrams plus text.** Each level is a diagram (component/package/class
  notation, UML or an informal boxes-and-lines sketch) accompanied by the
  black-box or white-box descriptions. The diagram alone is not the view; the
  descriptions carry the responsibilities and interfaces.
- **Black boxes: table or template.** For a short, pragmatic overview, *"use one
  table for a short and pragmatic overview of all contained building blocks and
  their interfaces"* — typically a **Name / Responsibility** table. For blocks
  that need more, use the full black-box template as a sub-heading per block.
- **Interfaces.** arc42 offers no fixed interface template; describe each only as
  far as understanding requires — often a signature or an example is enough.
- **Source-code mapping is optional.** Directory/file location is an optional
  black-box field. Where the mapping from a block to its code is non-obvious,
  say where the code lives; keep the mapping simple and straightforward. Per the
  house rule, name the class and method rather than a line number.

## How much is enough

**Level 1 is the floor, not a suggestion.** Even under tight documentation
budgets, describe level 1 — it makes the top-level structure explicit, stays
stable over time, and therefore costs little to maintain. That is the minimum a
complete section 5 must clear.

**Refinement is partial by design.** The white-box tree *"should be partial, you
should refine only some of the building blocks."* Prefer relevance over
completeness: open up the *"important, surprising, risky, complex or volatile"*
blocks and *"leave out normal, simple, boring or standardized parts."* A section
5 with a solid level 1 and one or two justified level-2 refinements is
**complete**, not thin — do not flag it for stopping there. Conversely, a
document that mechanically refines every block down several levels is bloated,
not thorough.

## Example

A good section 5 for **RosterRail** (see the example system in
[`../00-index.md`](../00-index.md)):

> ### Level 1 — Whitebox RosterRail
>
> ![Level 1 overview: staff SSO and the HMIS warehouse sit outside RosterRail;
> inside are Intake, CaseAssignment, EnrollmentTracking and WarehouseExport, all
> reading and writing one PostgreSQL store.]
>
> **Motivation.** The decomposition follows the agency's workflow — a client is
> intaken, assigned a case manager, and enrolled — plus one block isolating the
> outbound warehouse contract, the part most likely to change independently.
>
> | Name | Responsibility |
> |------|----------------|
> | Intake | Creates and validates client records at first contact. |
> | CaseAssignment | Assigns clients to case managers and enforces who may see whom. |
> | EnrollmentTracking | Records and updates program enrollments over time. |
> | WarehouseExport | Builds and sends the nightly enrollment extract to the HMIS warehouse. |
> | _Staff SSO_ (external) | Third-party identity provider; authenticates staff. Not ours — shown for context. |
>
> ### Level 2 — Whitebox WarehouseExport
>
> **Why refine this one?** It owns the only external write contract and the
> retry/idempotency behaviour behind quality goal 2, so it is worth opening;
> Intake and EnrollmentTracking are routine CRUD and are left as black boxes.
>
> | Name | Responsibility |
> |------|----------------|
> | ExtractBuilder | Selects the day's enrollments and serializes them to the warehouse format. |
> | ExtractSender | Posts the batch over REST and confirms receipt. |
> | ExtractLedger | Records what was sent so a failed run resends the full day with no duplicates. |

Level 1 names every block with a one-line responsibility and marks the external
SSO as third-party; exactly one level-1 block is refined, with a stated reason.
That is enough.

## Common mistakes

- **No level 1 — straight to detail.** Class-level or level-3 diagrams with no
  top-level whitebox. Source (Tip 5-3): *"Always describe level-1 of the
  building block view"* — it *"makes the top-level structure of building blocks
  explicit."*
- **Named boxes without responsibilities.** A diagram of labelled boxes where no
  block says what it is responsible for. Source (Tip 5-5): *"a brief description
  of its responsibility belongs to the really important aspects of the building
  block view."*
- **Leaky-abstraction responsibilities.** A responsibility strung together with
  many "and"s signals a block that is really several. Source (Tip 5-5): an
  abundance of "and" *"may signal an undefined abstraction."*
- **Decomposition with no rationale.** A whitebox that shows five parts but never
  says why. Source (Tip 5-8): *"In every whitebox you should briefly explain the
  reasons for the specific decomposition or structure."*
- **Refining everything.** Opening every block down several levels regardless of
  importance — bloat dressed as thoroughness. Source (Tip 5-27): the tree
  *"should be partial."*

## Belongs elsewhere

- **Dynamic behaviour, sequences, "who calls whom when" → section 6 (Runtime
  View).** This view is the *static* decomposition. Source: *"The building block
  view shows the static decomposition of the system into building blocks … as
  well as their dependencies."* Interaction over time is runtime.
- **Patterns and solutions shared across many blocks → section 8 (Crosscutting
  Concepts).** Describe the shared concept once and reference it. Source (Tip
  5-28 / 5-10): *"Explain concepts instead of building blocks"* to avoid
  repeating the same explanation in every block.
- **Mapping of blocks onto infrastructure/nodes → section 7 (Deployment View).**
  Section 5 is code structure, not where it runs.
- **Broad technology or structural decisions and their trade-offs → section 9
  (Architecture Decisions).** The *local* rationale for one whitebox's
  decomposition stays here (Tip 5-8); a system-wide decision with alternatives
  weighed is an ADR.

## Review rules

Severities derive from the arc42 source's own language. The overall view is
stated as **mandatory**, which justifies a `MUST` for its presence; the
remaining guidance uses advisory phrasing ("you should…", "belongs to the really
important aspects"), so those are `SHOULD`, and the optional black-box fields
yield a `MAY`. The global `HOUSE-CODEREF-1` rule in
[`../CONVENTIONS.md`](../CONVENTIONS.md) also applies.

- **`A42-5-01` (MUST)** — A level-1 whitebox of the overall system is present: an
  overview of the whole system decomposed into its contained building blocks.
  - *Check:* the chapter contains a top-level ("Level 1" / whitebox overall
    system) decomposition showing the system's constituent blocks; flag a chapter
    that has only class-level or deeper detail with no system-level whitebox.
  - *Fail:* the chapter opens directly with a level-3 class diagram of one module.
  - *Pass:* a "Level 1 — Whitebox <system>" section listing the contained blocks.
  - *Source:* *"This view is mandatory for every architecture documentation"*;
    *"Level 1 is the white box description of the overall system"* —
    <https://raw.githubusercontent.com/arc42/arc42-template/master/EN/adoc/05_building_block_view.adoc>.
    Tip 5-3 *"Always describe level-1."*

- **`A42-5-02` (SHOULD)** — Every level-1 black box has a stated
  responsibility/purpose, not just a name.
  - *Check:* each contained block (table row or black-box sub-heading) carries a
    responsibility sentence; flag a diagram of named boxes with no
    responsibilities.
  - *Fail:* `| CaseAssignment | |` — a name with an empty responsibility.
  - *Pass:* `| CaseAssignment | Assigns clients to case managers and enforces access. |`
  - *Source:* Tip 5-5 *"a brief description of its responsibility belongs to the
    really important aspects of the building block view."* Black-box template
    field *"Purpose/Responsibility"* in the canonical chapter.

- **`A42-5-03` (SHOULD)** — The level-1 whitebox includes both an overview diagram
  and a motivation for the decomposition.
  - *Check:* a diagram (or image reference) is present *and* at least a sentence
    of motivation for why the system is split this way; flag a bare table with
    neither.
  - *Source:* white-box template — *"an overview diagram"*, *"a motivation for
    the decomposition"* —
    <https://raw.githubusercontent.com/arc42/arc42-template/master/EN/adoc/05_building_block_view.adoc>.

- **`A42-5-04` (SHOULD)** — Every whitebox (each block that is opened into a lower
  level) explains the reason for its decomposition.
  - *Check:* each level-2+ refinement carries a rationale sentence ("why these
    parts / why they talk to each other"); flag a refinement that only lists
    parts.
  - *Fail:* "WarehouseExport contains ExtractBuilder, ExtractSender, ExtractLedger." (no why)
  - *Pass:* "WarehouseExport is refined because it owns the external write
    contract; ExtractLedger exists so a failed run resends with no duplicates."
  - *Source:* Tip 5-8 *"In every whitebox you should briefly explain the reasons
    for the specific decomposition or structure."*

- **`A42-5-05` (SHOULD)** — The external interfaces shown at level 1 are
  consistent with the system's context (section 3).
  - *Check:* the external partners/interfaces on the level-1 whitebox match the
    external interfaces named in section 3; flag a level-1 external actor that
    appears nowhere in context, or a context interface absent from level 1.
  - *Source:* Tip 5-3 — level 1 *"needs to be consistent (with respect to
    external interfaces) to the system scope and context."*

- **`A42-5-06` (MAY)** — Where a block's mapping to source code is non-obvious,
  its directory/file location is given.
  - *Check:* blocks whose code location does not follow obviously from their name
    state where the code lives; a document omitting all locations is *not* a
    violation, since the field is optional.
  - *Source:* black-box template optional field *"directory/file location"*;
    Tip 5-13 *"keep that mapping simple and straightforward"* and document it
    where complex.

## Sources

- **Canonical chapter (authoritative for subsection structure and numbering):**
  `05_building_block_view.adoc`, arc42-template 9.0-EN, git SHA `8dff0d9b`, read
  locally from `/tmp/arc42-template/EN/adoc/05_building_block_view.adoc`. Cite by
  raw URL —
  <https://raw.githubusercontent.com/arc42/arc42-template/master/EN/adoc/05_building_block_view.adoc>.
  Retrieved 2026-08-23.
- **Section page (Contents, Motivation, Form):**
  <https://docs.arc42.org/section-5/>. Retrieved 2026-08-23.
- **Tips fetched** (checkable review criteria only): 5-3 (always describe level-1;
  external-interface consistency), 5-5 (black-box responsibility; "and" =
  leaky abstraction), 5-8 (justify every whitebox), 5-13 (source-code mapping),
  5-27 (refinement is partial). Each at `https://docs.arc42.org/tips/5-<n>/`,
  retrieved 2026-08-23.
- **Tips skipped** (authoring advice, not distinct review criteria — a later pass
  may revisit): 5-1, 5-2, 5-4, 5-6, 5-7, 5-9, 5-10, 5-11, 5-12, 5-14, 5-15,
  5-16, 5-17, 5-18, 5-19, 5-20, 5-21, 5-22, 5-23, 5-24, 5-25, 5-26, 5-28. Of
  these, 5-2/5-11 (hierarchy) and 5-6 (hide internals) restate the level model
  already in the canonical chapter; 5-10/5-28 inform *Belongs elsewhere*
  (crosscutting concepts) without a separate mechanical rule.
- **License:** arc42 template CC BY-SA 4.0; attribution in
  [`../00-index.md`](../00-index.md).
