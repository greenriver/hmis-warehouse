# 07. Deployment View

## Purpose

This chapter answers one question for a reviewer: **where does this system
actually run, and which software runs on which piece of infrastructure?** It
maps the software building blocks from section 5 onto the technical
infrastructure — machines, environments, networks, containers — that executes
them. Its motivation is blunt: *"Software does not run without hardware. This
underlying infrastructure can and will influence a system and/or some
cross-cutting concepts."* If a reviewer cannot tell from this chapter what runs
where, or the diagram shows boxes and wires but never says which building block
lands on which node, the chapter has not done its job.

## What belongs here

arc42 structures this chapter as a hierarchy of infrastructure levels, not as a
fixed list of named subsections:

- **Infrastructure Level 1** — the top-level deployment. arc42 asks for four
  things here: *"distribution of a system to multiple locations, environments,
  computers, processors, .., as well as physical connections between them"*;
  *"important justifications or motivations for this deployment structure"*;
  *"quality and/or performance features of this infrastructure"*; and *"mapping
  of software artifacts to elements of this infrastructure"*. The template ships
  the labelled slots **Overview Diagram**, **Motivation**, **Quality and/or
  Performance Features**, and **Mapping of Building Blocks to Infrastructure**.
- **Infrastructure Level 2** — zoom-in on selected Level 1 elements: *"the
  internal structure of (some) infrastructure elements from level 1"*, one
  `Infrastructure Element` subsection per element that needs detail, reusing the
  Level 1 structure.

Two further points from the source: when the system runs in more than one
environment, *"you should document all relevant environments"* (dev, test,
production); and *"Especially document a deployment view if your software is
executed as distributed system with more than one computer, processor, server
or container."*

## Form & notation

- **Diagrams** — *"UML offers deployment diagrams to express that view. Use it,
  probably with nested diagrams, when your infrastructure is more complex."* Any
  notation is acceptable if stakeholders prefer it, as long as it shows *"nodes
  and channels of the infrastructure."* When symbols are drawn, Tip 7-1 asks for
  *"a consistent set of such symbols with a defined semantic."*
- **Combination** — arc42 expects *"a combination of diagrams, tables, and
  text"*. The mapping of building blocks to nodes is well suited to a table
  (Tip 7-7) or a UML deployment diagram (Tip 7-6).
- **Node detail** — where hardware matters, Tip 7-2 suggests a node-template
  capturing the node's responsibility, characteristics, hosted software, and the
  rationale for choosing it.

## How much is enough

Scope is bounded by software need: *"From a software perspective it is
sufficient to capture only those elements of an infrastructure that are needed
to show a deployment of your building blocks."* For a simple single-node system,
one Level 1 diagram plus a building-block-to-node mapping is **complete** — do
not flag the absence of Level 2 or of multiple environments as a deficiency.
Add Level 2 only for elements with *"high importance or special meaning"*, and
document multiple environments only when they exist and differ. The pressure
runs the other way for distributed systems: arc42 says to *especially* document
this view when the system spans more than one computer, server, or container, so
a distributed system with no deployment view is the gap to flag.

## Example

A good section 7 for **RosterRail** (see the example system in
[`../00-index.md`](../00-index.md)):

> ### Infrastructure Level 1
>
> **Overview Diagram**
>
> ```
> [Staff browser] --HTTPS--> [Load balancer]
>                                  |
>                    +------------------------------+
>                    |     App tier (2x container)  |  <-- Rails + React
>                    +------------------------------+
>                        |                    |
>                 [PostgreSQL primary]   [External SSO]
>                        |
>                 [Nightly extract job] --REST--> [HMIS warehouse]
> ```
>
> **Motivation** — Two stateless app containers behind a load balancer give us
> rolling deploys and survive a single-container failure; the database is a
> single managed PostgreSQL instance because our write volume is low and a
> managed primary with point-in-time recovery meets our reliability goal without
> the operational cost of self-managed replication.
>
> **Quality and/or Performance Features** — App tier scales horizontally;
> managed PostgreSQL provides automated backups and point-in-time recovery;
> SSO is external so no staff credentials are stored in RosterRail.
>
> **Mapping of Building Blocks to Infrastructure**
>
> | Building block (section 5) | Node                     |
> |----------------------------|--------------------------|
> | Web/API app, React frontend | App container (2x)      |
> | Enrollment store           | PostgreSQL primary       |
> | Nightly extract worker     | Scheduled job container  |
> | Authentication             | External SSO provider    |
>
> **Environments** — DEV, TEST, and PROD share this topology; DEV and TEST run a
> single app container and a smaller database, and TEST points at the HMIS
> warehouse *sandbox* endpoint rather than production.
>
> ### Infrastructure Level 2
>
> #### PostgreSQL primary
>
> Managed instance, daily snapshots plus WAL archiving for point-in-time
> recovery. Special because it is the single stateful node and the recovery
> target for the reliability quality goal; failure here halts intake, so its
> backup and restore path is documented in section 8.

One Level 1 diagram with an explicit building-block-to-node mapping, a stated
motivation, the environments and how they differ, and one zoomed-in node that
earns Level 2 detail. That is enough.

## Common mistakes

- **A diagram with no mapping.** A network or ops diagram that shows nodes and
  wires but never says which building block runs on which node fails the
  chapter's core purpose. Source: Content *"mapping of (software) building
  blocks to that infrastructure elements"*; Tip 7-5 *"you should explain the
  mapping of your building blocks to that hardware."*
- **Only production documented.** When dev/test/prod differ, showing only one
  hides the differences that cause deploy surprises. Source (Tip 7-3): *"you
  should document these environments plus possible differences between them."*
- **Nodes drawn but not explained.** Important nodes appear in the diagram with
  no word on why they matter. Source (Tip 7-8): *"you should explain those
  nodes, what there properties are and why they are so special for the system or
  its operation."*
- **Inconsistent diagram symbols.** Ad-hoc iconography with no key. Source (Tip
  7-1): *"use a consistent set of such symbols with a defined semantic."*
- **Re-drawing the section 3 black box.** Repeating the single-black-box
  technical context instead of zooming into it. Source: *"Maybe a highest level
  deployment diagram is already contained in section 3.2. as technical context
  with your own infrastructure as ONE black box. In this section one can zoom
  into this black box."*

## Belongs elsewhere

- **External systems and the system-as-one-black-box → section 3 (Context and
  Scope).** The top-level technical context (who RosterRail talks to) lives in
  3.2; section 7 zooms into RosterRail's own infrastructure. Source: *"Maybe a
  highest level deployment diagram is already contained in section 3.2. as
  technical context with your own infrastructure as ONE black box."*
- **Internal decomposition of a building block → section 5 (Building Block
  View).** Section 7 places building blocks onto nodes; it does not decompose
  them.
- **Time-ordered interaction between nodes → section 6 (Runtime View).** How a
  request flows across the tier over time is runtime behavior, not deployment
  structure.
- **Standalone rationale for a deployment technology choice → section 9
  (Architecture Decisions).** A one-line motivation for the topology belongs
  here (Level 1 asks for it); a full decision record with alternatives and
  consequences is an ADR.

## Review rules

Severities derive from the arc42 source's own language. The template and its
tips are advisory — the environments guidance and Tips 7-3, 7-5, and 7-8 use
*"you should"*, Tip 7-1 uses the imperative *"Describe"*, and Tip 7-4 uses *"you
can"* — so these are `SHOULD` or `MAY`, never `MUST`. The global
`HOUSE-CODEREF-1` rule in [`../CONVENTIONS.md`](../CONVENTIONS.md) also applies.

- **`A42-7-01` (SHOULD)** — The chapter presents an Infrastructure Level 1
  deployment description with a diagram (or equivalent) showing the
  infrastructure nodes and the channels between them.
  - *Check:* an overview diagram or node/channel description is present; nodes
    and their connections are both shown.
  - *Fail:* a paragraph naming "the server" with no nodes or connections.
  - *Pass:* a deployment diagram (or node table) with nodes and the channels
    linking them.
  - *Source:* Content *"infrastructure elements like … computers, processors,
    channels and net topologies"*; Form *"nodes and channels of the
    infrastructure"*; Tip 7-1 *"Describe the technical infrastructure … nodes …
    and their relations (channels)"* —
    <https://raw.githubusercontent.com/arc42/arc42-template/master/EN/adoc/07_deployment_view.adoc>,
    <https://docs.arc42.org/tips/7-1/>.

- **`A42-7-02` (SHOULD)** — The chapter maps software building blocks (section 5)
  onto infrastructure elements.
  - *Check:* a table, diagram annotation, or prose states which building block
    runs on which node; flag a deployment diagram with no such mapping.
  - *Fail:* an infrastructure diagram with no reference to any building block.
  - *Pass:* a `Building block | Node` table, or nodes annotated with the
    components they host.
  - *Source:* Content *"mapping of (software) building blocks to that
    infrastructure elements"*; Level 1 *"mapping of software artifacts to
    elements of this infrastructure"*; Tip 7-5 *"you should explain the mapping
    of your building blocks to that hardware"* —
    <https://raw.githubusercontent.com/arc42/arc42-template/master/EN/adoc/07_deployment_view.adoc>,
    <https://docs.arc42.org/tips/7-5/>.

- **`A42-7-03` (SHOULD)** — When the system runs in more than one environment,
  the relevant environments and their differences are documented.
  - *Check:* if the document, section 2, or the deployment text implies multiple
    environments (dev/test/prod), each relevant one is described with its
    differences; a single-environment system is exempt.
  - *Fail:* text mentions a staging environment but describes only production.
  - *Pass:* "DEV/TEST/PROD share the topology; TEST uses the warehouse sandbox
    endpoint."
  - *Source:* *"you should document all relevant environments"*; Tip 7-3 *"you
    should document these environments plus possible differences between them"* —
    <https://raw.githubusercontent.com/arc42/arc42-template/master/EN/adoc/07_deployment_view.adoc>,
    <https://docs.arc42.org/tips/7-3/>.

- **`A42-7-04` (SHOULD)** — The chapter states the motivation for the deployment
  structure and its quality/performance features.
  - *Check:* Level 1 includes at least a short justification for the topology and
    a note on its quality or performance characteristics; flag a diagram with no
    accompanying "why".
  - *Fail:* a topology diagram with no text explaining why it is shaped that way.
  - *Pass:* "Two app containers behind a load balancer for rolling deploys and
    single-node failure tolerance."
  - *Source:* Level 1 *"important justifications or motivations for this
    deployment structure"* and *"quality and/or performance features of this
    infrastructure"*; Tip 7-2 *"it is useful to understand the reasoning behind
    the hardware decisions"* —
    <https://raw.githubusercontent.com/arc42/arc42-template/master/EN/adoc/07_deployment_view.adoc>,
    <https://docs.arc42.org/tips/7-2/>.

- **`A42-7-05` (SHOULD)** — Nodes with special importance are explained (their
  properties and why they matter), not merely drawn.
  - *Check:* for each node the text flags as important/special, there is prose
    giving its properties and its significance; flag important nodes that appear
    only in the diagram.
  - *Fail:* a "PostgreSQL primary" box with no further explanation.
  - *Pass:* "PostgreSQL primary — single stateful node, PITR target for the
    reliability goal; failure halts intake."
  - *Source:* Tip 7-8 *"you should explain those nodes, what there properties are
    and why they are so special for the system or its operation"*; Level 2
    *"internal structure of (some) infrastructure elements from level 1"* —
    <https://docs.arc42.org/tips/7-8/>,
    <https://raw.githubusercontent.com/arc42/arc42-template/master/EN/adoc/07_deployment_view.adoc>.

- **`A42-7-06` (MAY)** — For a heterogeneous or distributed system, the
  deployment view may be organized hierarchically (Infrastructure Level 1, then
  Level 2 for selected elements).
  - *Check:* presence of Level 2 zoom-in subsections is optional; do not flag a
    simple system for having only Level 1.
  - *Source:* Tip 7-4 *"you can organize and document the deployment view as a
    hierarchy"* (note the permissive *"can"*, hence `MAY`); Level 2 subsection in
    the template —
    <https://docs.arc42.org/tips/7-4/>,
    <https://raw.githubusercontent.com/arc42/arc42-template/master/EN/adoc/07_deployment_view.adoc>.

## Sources

- **Canonical chapter (authoritative for subsection structure and numbering):**
  `07_deployment_view.adoc`, arc42-template 9.0-EN, git SHA `8dff0d9b`, read
  locally from `/tmp/arc42-template/EN/adoc/07_deployment_view.adoc`. Cite by raw
  URL —
  <https://raw.githubusercontent.com/arc42/arc42-template/master/EN/adoc/07_deployment_view.adoc>.
  Retrieved 2026-08-23.
- **Section page (Contents, Motivation, Form):**
  <https://docs.arc42.org/section-7/>. Retrieved 2026-08-23.
- **Tips fetched** (checkable review criteria only): 7-1 (document infrastructure
  nodes/channels, consistent symbols), 7-2 (explain hardware decisions /
  motivation), 7-3 (document environments and their differences), 7-4
  (hierarchical organization — permissive), 7-5 (mapping of building blocks to
  hardware), 7-8 (explain special nodes). All `https://docs.arc42.org/tips/7-N/`,
  retrieved 2026-08-23.
- **Tips skipped** (notation or authoring advice, not separate review criteria —
  a later pass may revisit): 7-6 (use UML deployment diagrams) and 7-7 (use
  tables) inform *Form & notation* but yield no rule beyond `A42-7-01`/`A42-7-02`;
  7-9 (explain what else is relevant for operation) and 7-10 (leave hardware
  decisions to hardware experts) are operational/organizational advice.
- **License:** arc42 template CC BY-SA 4.0; attribution in
  [`../00-index.md`](../00-index.md).
