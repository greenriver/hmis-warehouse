# 08. Crosscutting Concepts

## Purpose

This chapter answers one question for a reviewer: **are the solution ideas that
span more than one building block written down once, in the open, instead of
being re-invented (or silently diverging) inside each component?** Crosscutting
concepts — how the system logs, authorizes, persists, handles errors, models its
domain — are what give an architecture its *conceptual integrity*: the property
that two engineers solving the same recurring problem in two different places
solve it the same way. If those concepts live only in people's heads or scattered
across the code, the architecture drifts. Section 8 is the central place that
holds them, so the rest of the documentation (and the code) can point at one
authoritative description rather than repeating it. Source: *"Concepts form the
basis for conceptual integrity (consistency, homogeneity) of the architecture."*

## What belongs here

Crosscutting concepts: *"practices, patterns, regulations or solution ideas"*
that are *"often related to multiple building blocks."* A concept is a
recurring, reusable solution — authentication, logging, transaction handling, the
domain model, error handling, an internationalization approach — as opposed to
the description of any single component.

Unlike most arc42 chapters, section 8 has **no fixed named subsections**. The
template ships placeholders — *<Concept 1>*, *<Concept 2>*, … *<Concept n>* —
and instructs you to *"Pick only the most-needed topics for your system and
assign each a level-2 heading in this section (e.g. 8.1, 8.2 etc)."* So the
"official structure" here is simply: one numbered subsection per concept you
chose to document. There is no required set of concept names to check against;
what you check is that each concept present is a genuine crosscutting concern,
explained concretely.

arc42 supplies a diagram of possible topics and, per Tip 8-3, *"a list of more
than 20 proposals for recurring topics — way too many for most real-life
systems."* That catalog is a menu to select from, **not** a checklist to
complete.

## Form & notation

The template deliberately leaves the form open. Three shapes are named:

- **Concept papers** — *"concept papers with any kind of structure."* Prose plus
  a diagram is the common case.
- **Example implementations** — *"example implementations, especially for
  technical concepts."* A concept is best shown by the code that realises it.
- **Cross-cutting model excerpts or scenarios** — *"cross-cutting model excerpts
  or scenarios using notations of the architecture views."* A concept may be
  illustrated with a runtime scenario or a model fragment drawn in the same
  notation used in sections 5 and 6.

Source code is encouraged as illustration but with restraint: show *"selected
unit tests"* and *"restrict it to fundamental or important segments only,
avoiding extensive code fragments"* (Tip 8-8). Reference code by its identity —
per this reference's `HOUSE-CODEREF-1`, a class and method, not a file line
number — rather than pasting large blocks that rot.

## How much is enough

A handful of concepts, each explained concretely, is the target. Tip 8-3 is
explicit that the 20-plus proposed topics are *"way too many for most real-life
systems"* and prescribes: *"Select those that are absolutely relevant or
necessary for your system"*, *"assign priorities"*, and elaborate only the
top-priority ones. A lean section 8 with two to four well-explained concepts is
**complete**, not deficient — do not flag it for brevity. The failure mode is the
opposite: a section that reproduces the whole arc42 topic catalog as empty or
one-line headings. Depth beats breadth here; an unexplained concept is worse than
an omitted one.

## Example

A good section 8 for **RosterRail** (see the example system in
[`../00-index.md`](../00-index.md)) documents two concepts — no attempt at the
full catalog:

> ### 8.1 Record-level authorization
>
> Every read or write of client data is scoped to the case managers assigned to
> that client; unassigned staff are denied and the attempt is logged. This is a
> crosscutting concern: it applies to **every** building block that touches a
> client record (the intake service, the enrollment tracker, the extract job),
> so it is defined once here rather than re-checked ad hoc in each.
>
> **How it works.** Controllers call a single policy object,
> `ClientPolicy#accessible?`, which resolves the current staff member's
> assignments and returns the permitted client scope; controllers authorize
> against that scope rather than loading a record first. The denial path raises
> `AccessDenied`, caught centrally and recorded by `AuditLog#record_denial`.
>
> ```ruby
> # illustrative — the authorization gate, not the full policy
> def show
>   client = ClientPolicy.new(current_user).accessible.find(params[:id])
>   # ...
> end
> ```
>
> **Affects:** Intake service (5.2), Enrollment tracker (5.3), Nightly extract
> (5.4).
>
> ### 8.2 Idempotent nightly extract
>
> The extract to the downstream HMIS warehouse must be safe to re-run after a
> failure without creating duplicates. Each run is keyed by extract date; the
> warehouse upserts on `(data_source_id, enrollment_id, extract_date)`, so a
> re-run of a partial day overwrites rather than appends. Retries are the normal
> recovery path, driven by `ExtractJob#perform` with the date as its idempotency
> key.
>
> **Affects:** Nightly extract (5.4) and its REST contract with the warehouse (3.2).

Two concepts, each stating what it is, *how* it works, and which building blocks
it crosscuts; code shown as a short referenced excerpt. That is enough.

## Common mistakes

- **The whole catalog as empty headings.** Copying arc42's 20-plus topic list in
  as one-line stubs. Source: *"DO NOT ATTEMPT to cover all of the topics"*; Tip
  8-3 *"way too many for most real-life systems."*
- **Named but not explained.** A heading ("Logging", "Security") with a sentence
  that restates the title instead of describing the mechanism. Source (Tip 8-4):
  *"document or specify concrete, real solution approaches, not abstract
  theories. Explain, how these concepts are applied in reality."*
- **A one-off decision filed as a concept.** A choice made once, for one
  component, with no reusable pattern behind it, belongs in section 9. Source
  (Tip 8-9): *"if (extensive-explanation-required) then concept else decision."*
- **Large pasted code.** Whole classes dumped inline; they duplicate the source
  and rot. Source (Tip 8-8): *"avoiding extensive code fragments."*
- **No link to the building blocks.** A concept described in isolation, with no
  statement of which parts of the system it governs, cannot be traced. Source
  (Tip 8-11): *"(Hyper)Link between Building Blocks and Concepts."*

## Belongs elsewhere

- **A single architectural or design decision → section 9 (Architecture
  Decisions).** arc42 treats concepts as the *"special cases"* worth extensive
  explanation; a bare decision that needs only its rationale recorded goes in
  section 9. Source (Tip 8-9): *"You can interpret concepts as special cases of
  architecture and/or design decisions (see arc42 section 9)."*
- **The building block catalog itself → section 5 (Building Block View).**
  Section 8 describes concerns that *cut across* building blocks; the blocks,
  their responsibilities and interfaces are section 5's job. A concept references
  the blocks it affects, it does not re-specify them.
- **Detailed, measurable quality requirements → section 10 (Quality
  Requirements).** A concept may explain *how* the system meets a quality goal,
  but the goal itself, with its measurable scenario, lives in section 10. (Note:
  a cross-cutting *scenario* used to illustrate a concept is explicitly allowed
  here — Form: *"scenarios using notations of the architecture views."*)

## Review rules

Severities derive from the arc42 source's own language. The template is advisory
in most places (descriptive phrasing rather than RFC-2119 "must"), so those rules
are `SHOULD`. The one exception is the emphatic, capitalised prohibition against
covering every topic, which the source states as a command (*"Pick **only** …"*,
*"DO NOT ATTEMPT …"*) — rated `MUST`. The global `HOUSE-CODEREF-1` rule in
[`../CONVENTIONS.md`](../CONVENTIONS.md) also applies.

- **`A42-8-01` (SHOULD)** — Each documented concept is its own level-2
  subsection.
  - *Check:* every concept is a distinct heading under section 8 (8.1, 8.2, …);
    flag concepts run together in a single undifferentiated blob.
  - *Source:* *"assign each a level-2 heading in this section (e.g. 8.1, 8.2
    etc)"* —
    <https://raw.githubusercontent.com/arc42/arc42-template/master/EN/adoc/08_concepts.adoc>.

- **`A42-8-02` (MUST)** — The section documents a *selected* subset of concepts,
  not an attempt at exhaustive coverage of every arc42 topic.
  - *Check:* flag if the concept subsections reproduce the arc42 topic catalogue
    wholesale (as a proxy, more than ~10 concept headings, or a run of one-line
    headings with no explanatory body).
  - *Fail:* twelve headings — "Logging", "Security", "Persistence", … — each with
    no body.
  - *Pass:* three concepts, each with a "how it works" explanation.
  - *Source:* *"Pick **only** the most-needed topics for your system"*, *"DO NOT
    ATTEMPT to cover all of the topics"*
    (<https://raw.githubusercontent.com/arc42/arc42-template/master/EN/adoc/08_concepts.adoc>);
    Tip 8-3 *"more than 20 proposals … way too many … Select those that are
    absolutely relevant."*

- **`A42-8-03` (SHOULD)** — Each concept explains *how* it works, not just its
  name.
  - *Check:* each concept subsection contains prose describing the concrete
    solution approach (the mechanism, or how it is applied in the code); flag a
    heading whose body only restates the title or gives an abstract definition.
  - *Fail:* `### 8.1 Logging` — "We log important events."
  - *Pass:* `### 8.1 Logging` — "All requests pass through `RequestLogger`, which
    emits one structured JSON line per request keyed by request id; downstream
    jobs propagate that id so a request can be traced across the extract."
  - *Source:* Tip 8-4 *"document or specify concrete, real solution approaches,
    not abstract theories. Explain, how these concepts are applied in reality."*

- **`A42-8-04` (SHOULD)** — Each concept states which building blocks or parts of
  the system it applies to.
  - *Check:* each concept subsection names the building blocks / components it
    crosscuts; flag a concept described with no link to where it applies.
  - *Source:* *"Such concepts are often related to multiple building blocks"*
    (<https://raw.githubusercontent.com/arc42/arc42-template/master/EN/adoc/08_concepts.adoc>);
    Tip 8-11 *"(Hyper)Link between Building Blocks and Concepts."*

- **`A42-8-05` (SHOULD)** — Code shown inline is a short, referenced excerpt, not
  a large copy-pasted fragment.
  - *Check:* inline code blocks are minimal and point at their source (per
    `HOUSE-CODEREF-1`, by class and method); flag whole classes/files pasted in.
  - *Source:* Tip 8-8 *"restrict it to fundamental or important segments only,
    avoiding extensive code fragments"*; Form *"example implementations,
    especially for technical concepts."*

## Sources

- **Canonical chapter (authoritative for structure and numbering):**
  `08_concepts.adoc`, arc42-template 9.0-EN, git SHA `8dff0d9b`, read locally
  from `/tmp/arc42-template/EN/adoc/08_concepts.adoc`. Cite by raw URL —
  <https://raw.githubusercontent.com/arc42/arc42-template/master/EN/adoc/08_concepts.adoc>.
  Retrieved 2026-08-23. (Upstream spells the heading "Cross-cutting Concepts";
  our published title is "Crosscutting Concepts" per
  [`../CONVENTIONS.md`](../CONVENTIONS.md) — a spelling difference only.)
- **Section page (Contents, Motivation, Form):**
  <https://docs.arc42.org/section-8/>. Retrieved 2026-08-23.
- **Tips fetched** (checkable review criteria only): 8-1 (concepts are the
  fundamental solution approaches), 8-3 (select the most important; 20+ topics
  too many), 8-4 (explain HOW, concrete not abstract), 8-8 (source code as
  illustration, minimal excerpts), 8-9 (a bare decision belongs in section 9),
  8-11 (link concepts to building blocks). All under
  <https://docs.arc42.org/tips/>, retrieved 2026-08-23.
- **Tips skipped** (authoring advice or definitional, not mechanical review
  criteria — a later pass may revisit): 8-2 (what "concept" covers), 8-5
  (document domain models), 8-6 (combine domain model with the glossary), 8-7
  (document the data model), 8-10 (use the arc42 collection as a checklist). 8-5
  and 8-7 could seed a house rule on domain-model documentation if wanted; left
  out to keep the rule set tight.
- **License:** arc42 template CC BY-SA 4.0; attribution in
  [`../00-index.md`](../00-index.md).
