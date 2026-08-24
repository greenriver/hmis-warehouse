# 03. Context and Scope

## Purpose

This chapter answers one question for a reviewer: **do we know exactly where
this system ends and its environment begins, and is every communication partner
across that boundary accounted for?** Context and scope draws the black-box line
around the system, names everyone and everything on the other side of that line
(users, roles, neighboring IT systems), and specifies the external interfaces
that cross it. The template calls these interfaces "among your system's most
critical aspects" and tells the author to "make sure that you completely
understand them." A section 3 with a missing neighbor or an unstated interface
is the classic real-world defect this chapter exists to catch — which is why the
epic flags this section for the full treatment.

## What belongs here

arc42 splits this chapter into two official subsections:

- **Business Context** — a specification of *all* communication partners (users,
  IT systems, …) with the domain-specific inputs and outputs, and optionally the
  domain formats or protocols exchanged. It shows the system as a black box and
  its domain interfaces to each partner. *"Specification of all communication
  partners (users, IT-systems, …) with explanations of domain specific inputs
  and outputs or interfaces."*
- **Technical Context** — the technical interfaces (channels and transmission
  media) linking the system to its environment, plus a mapping of the
  domain-specific inputs/outputs onto those channels — i.e. which I/O travels
  over which channel. *"Technical interfaces (channels and transmission media)
  linking your system to its environment. In addition a mapping of domain
  specific input/output to the channels."*

The chapter's own overview names the split: *"If necessary, differentiate the
business context (domain specific inputs and outputs) from the technical context
(channels, protocols, hardware)."* The differentiation is optional in principle
but expected whenever hardware or technology matters to the system (Tip 3-10).

## Form & notation

- **Business Context** — a black-box diagram showing communication partners, a
  table, or both. The template's suggested table is titled with the system name
  and carries three columns: *the name of the communication partner, the inputs,
  and the outputs*. arc42 recommends combining a diagram with a table so the
  diagram stays uncluttered (short labels) while the table carries the
  explanations, rationale, and cross-references (Tip 3-3).
- **Technical Context** — arc42 suggests a UML deployment diagram describing the
  channels to neighboring systems, *"together with a mapping table showing the
  relationships between channels and input/output."* A partner reached over HTTPS
  in one row, over a nightly file drop in another, is exactly what this mapping
  captures.
- Overall notation options the template lists: *context diagrams* and *lists of
  communication partners and their interfaces.*

## How much is enough

Context is an **overview**, not an interface specification. The stop condition
has two halves that pull in opposite directions, and both must hold:

- **Complete in breadth.** Every external partner and interface appears — this is
  the one place arc42 asks for completeness. *"Show all (all!) external
  interfaces"* (Tip 3-9): "striving for completeness is (usually) a bad idea"
  everywhere else, but "include all (as in every) external systems into the
  context diagram." Where the count is large, cluster or categorize partners
  rather than dropping any (Tips 3-5, 3-9).
- **Shallow in depth.** Do not drill into field-level message schemas, endpoint
  catalogues, or infrastructure topology here. *"Restrict the context to an
  overview, avoid too many details"* (Tip 3-5): document all neighbours, but
  keep each to the black-box level; detailed interface specs and deployment
  topology live in later chapters.

A section 3 that names every neighbor, states each interface at the black-box
level, and stops there is **complete**, not thin. Do not flag it for lacking
message-level detail — that detail deliberately belongs elsewhere.

## Example

A good section 3 for **RosterRail** (see the example system in
[`../00-index.md`](../00-index.md)):

> ### Business Context
>
> RosterRail (black box) and its communication partners:
>
> | Communication partner | Input to RosterRail                                   | Output from RosterRail                                          |
> |-----------------------|-------------------------------------------------------|-----------------------------------------------------------------|
> | Case manager (staff)  | Client intake details, case-manager assignments, enrollment updates | Client records, enrollment status, only for assigned clients   |
> | SSO provider          | Signed identity assertion for a staff member          | Authentication request for a staff member                       |
> | HMIS warehouse        | Extract acknowledgement / failure notice              | Nightly enrollment extract (full day's client + enrollment records) |
>
> PostgreSQL is **inside** the RosterRail boundary and is therefore not a
> communication partner — it appears in the building block and deployment views,
> not here.
>
> ### Technical Context
>
> | Interface (partner)          | Channel / protocol                          | Domain I/O carried                          |
> |------------------------------|---------------------------------------------|---------------------------------------------|
> | Staff browser (case manager) | HTTPS, React SPA over a REST/JSON API        | Intake, assignment, enrollment views        |
> | SSO provider                 | OIDC over HTTPS (redirect + back-channel)    | Identity assertion / authentication request |
> | HMIS warehouse               | REST/JSON over HTTPS, nightly scheduled batch | Enrollment extract; acknowledgement          |
>
> Each domain interface in the Business Context maps to exactly one row here, so
> a reviewer can trace every partner from what it exchanges to how it is reached.

Three partners, each shown at the black-box level, and a technical mapping that
covers all three. That is enough — no message schemas, no deployment topology.

## Common mistakes

- **A missing communication partner.** The single completeness rule for context
  is that *every* external system appears; an omitted neighbor is the defect this
  chapter most exists to catch. Source: *"Specification of all communication
  partners"*; Tip 3-9 *"include all (as in every) external systems."*
- **System boundary left implicit.** If the reader cannot tell what is inside the
  system versus a neighbor, scope is undefined. Source (Tip 3-1): *"Define 'what's
  inside' your system and what's outside … That way you show the scope of your
  system."*
- **An over-detailed context.** Message field lists, per-endpoint contracts, or
  infrastructure topology drown the overview. Source (Tip 3-5): *"Restrict the
  context to an overview, avoid too many details."*
- **Business and technical context conflated.** One diagram that mixes domain
  partners with protocols and boxes serves neither audience. Source (Tip 3-10):
  differentiate the two whenever hardware or technology matters.
- **Internal data stores shown as partners.** A database or cache inside the
  boundary is not a communication partner; listing it inflates the context and
  blurs the scope line.

## Belongs elsewhere

- **Deployment topology, infrastructure, and hardware nodes → section 7
  (Deployment View).** The technical context gives a channel-level overview only;
  the full picture defers to deployment. Source (Tip 3-19): *"You can defer
  technology and infrastructure to the deployment view if you focus more on
  domain topics … If technology and infrastructure is important to you, then you
  should give this overview already in the technical context."*
- **Quality requirements on the external interfaces → section 10 (Quality
  Requirements).** Note *that* an interface exists here; its throughput or
  latency targets belong with the quality scenarios (Tip 3-14 flags attention to
  interface qualities, but the detailed requirements live in section 10).
- **Internal structure of the system → section 5 (Building Block View).** Context
  is a black box; what is inside it is the building block view's job.
- **Top stakeholders and their expectations → section 1 (Introduction and
  Goals).** Section 3 names partners and interface contracts; section 1 names
  stakeholders and what they expect.

## Review rules

Severities derive from the arc42 source's own language. The template is advisory
throughout — it describes forms ("Context diagrams", "a table") rather than using
RFC-2119 "must" — so these are `SHOULD`, not `MUST`, even where the template
emphasizes *all* communication partners. The global `HOUSE-CODEREF-1` rule in
[`../CONVENTIONS.md`](../CONVENTIONS.md) also applies.

- **`A42-3-01` (SHOULD)** — The chapter contains the two arc42 subsections:
  *Business Context* and *Technical Context*.
  - *Check:* both subsection headings are present (or obvious synonyms). A
    document that deliberately omits Technical Context because technology is
    immaterial should say so; flag a silent omission.
  - *Source:* the upstream chapter is structured as exactly these two `===`
    subsections; overview *"differentiate the business context … from the
    technical context"* —
    <https://raw.githubusercontent.com/arc42/arc42-template/master/EN/adoc/03_context_and_scope.adoc>.

- **`A42-3-02` (SHOULD)** — The Business Context presents the system as a black
  box via a context diagram, a partner table, or both.
  - *Check:* a context diagram is present, or a table whose rows are
    communication partners with input and output columns.
  - *Fail:* a paragraph asserting "the system integrates with several external
    systems" with no diagram and no partner list.
  - *Pass:* a table with `Communication partner | Input | Output` rows, one per
    neighbor.
  - *Source:* Form *"Context diagrams"* / *"Lists of communication partners and
    their interfaces"*; Business Context Form *"the three columns contain the
    name of the communication partner, the inputs, and the outputs"*; Tip 3-3.

- **`A42-3-03` (SHOULD)** — Every external communication partner is shown;
  clustering is allowed, silent omission is not.
  - *Check:* cross-check the partners in the context against neighbors named
    elsewhere in the document (e.g. quality goals, deployment); flag any external
    system referenced elsewhere but absent from the context. Aggregated clusters
    count as present.
  - *Fail:* the SSO provider drives a quality goal in section 1 but never appears
    in the context.
  - *Pass:* every external system named anywhere in the document also appears (by
    name or within a labelled cluster) in the context.
  - *Source:* *"Specification of all communication partners"* (emphasis in
    source); Tip 3-9 *"include all (as in every) external systems into the
    context diagram."*

- **`A42-3-04` (SHOULD)** — The Technical Context maps domain inputs/outputs onto
  channels or protocols.
  - *Check:* the technical context states, per interface, the channel or protocol
    used and which domain I/O it carries — a mapping table or equivalent.
  - *Fail:* a technical context listing protocols (HTTPS, SFTP) with no link back
    to which partner or data each serves.
  - *Pass:* rows pairing an interface with its channel and the domain I/O it
    carries.
  - *Source:* Technical Context Contents *"a mapping of domain specific
    input/output to the channels, i.e. an explanation which I/O uses which
    channel"*; Form *"a mapping table showing the relationships between channels
    and input/output."*

## Sources

- **Canonical chapter (authoritative for subsection structure and numbering):**
  `03_context_and_scope.adoc`, arc42-template 9.0-EN, git SHA `8dff0d9b`, read
  locally from `/tmp/arc42-template/EN/adoc/03_context_and_scope.adoc`. Cite by
  raw URL —
  <https://raw.githubusercontent.com/arc42/arc42-template/master/EN/adoc/03_context_and_scope.adoc>.
  Retrieved 2026-08-23.
- **Section page (Contents, Motivation, Form):**
  <https://docs.arc42.org/section-3/>. Retrieved 2026-08-23.
- **Tips fetched** (checkable review criteria or depth calibration): 3-1
  (demarcate the system), 3-3 (combine diagram with table), 3-5 (overview only —
  informs *How much is enough*), 3-9 (show all external interfaces), 3-10
  (differentiate business/technical), 3-19 (defer technical context to
  deployment). Each at `https://docs.arc42.org/tips/3-<n>/`, retrieved
  2026-08-23.
- **Tips skipped** (authoring technique, not review criteria — a later pass may
  revisit): 3-2 (show as diagram), 3-4 (indicate risks), 3-6 (categorize), 3-7
  (cluster external systems), 3-8 (cluster with ports), 3-11 (data flows vs
  dependencies), 3-12 (external influences), 3-13 (transitive dependencies), 3-14
  (quality requirements at interfaces — noted in *Belongs elsewhere*, no separate
  rule), 3-15 (technical context when hardware central), 3-16 (protocols/channels
  in technical context), 3-17 (combine business with technical), 3-18 (relate
  domain interfaces to technical realization).
- **License:** arc42 template CC BY-SA 4.0; attribution in
  [`../00-index.md`](../00-index.md).
