# ADR 0009: Client Data Retention and Removal

## Status

- Current Status: Proposed
- Date of last update: 2026-09-15
- Decision-makers: OP engineering team, OP support team

## Context

We have two obligations that pull against each other. Auditability asks us to
keep data around, so that any figure in a report can be traced back to the
records behind it. Client privacy asks for the opposite: hold the least PII for
the shortest time we can. Today the warehouse keeps everything it ingests,
indefinitely, with no way to say how long client data should stay.

- HUD reporting compliance requires a minimum of seven years of retention.
  Above that floor, customers set their own period. Communities differ in legal
  obligations and local policy, and may want different periods for different
  data sources, so a period imposed platform-wide does not fit.
- Removal of aged-out data is available as a one-off manual process today. The
  motivation for this ADR is customer demand and obligation to protect client
  data.
- The HUD 2004 HMIS Data and Technical Standards define protected personal
  information (PPI) as name, SSN, date of birth, ZIP code of last permanent
  address, program entry date, program exit date, unique person identification
  number, and program identification number. That list is wider than the fields
  scrubbing can plausibly clear: the last four are the structure reporting is
  built on, and scrubbing them would leave nothing to report against, which is the
  whole point of choosing Scrub over Delete.
- Communities may make different choices on hiding, scrubbing, or removal.
  There are real use cases for each.
- Without a shared position, new data-retaining features may each approach the
  question differently.
- ADR [0002 (PII Management Strategy)](0002-pii-management-strategy.md) covers PII
  tracking, access control, and non-production anonymization, but not retention
  or removal of aged-out client data.

## Decision

Provide a per-community, opt-in client data retention capability that is user
configurable. The platform supplies the mechanism; the community decides if and
how it runs.

- **Phased delivery.** Scrub and Delete are not achievable in the short term.
  The rest of this ADR describes the capability whole; phase boundaries are
  called out where they matter.
  - **Phase 1: aging plus Hide.** Build the machinery that identifies expired
    clients automatically — the configurable window and its per data source
    overrides, client-scoped aging across the rollup, the opt-in switch and
    on-demand run, and the run log. implement Hide as the only strategy it
    can apply.
  - **Later phases.** Scrub and Delete become available as additional
    strategies on the same machinery. Their order, scope, and timing are not
    decided.
- **Opt-in and user-triggered.** Retention processing is off by default. A
  community may enable it, disable it, or run it on demand.
- **Client-scoped aging.** Aging is never decided record by record. The unit is
  the destination client and every source client rolled into it: one record
  inside the window, in any of those sources, keeps the whole rollup, however
  old the rest of it is. Evaluation checks each source client against the window
  for its own data source, falling back to the global window, and the rollup
  ages out only when all of them have. Whatever is then applied — Hide, Scrub,
  or Delete — is applied to the rollup as a whole.
  - **Scrubbed rollups are held together by their links, not by their data.**
    Blanking name and SSN destroys the evidence the rollup was built from, so
    the existing links between the sources and their destination become the
    only record that these are one person, and they must be preserved and
    treated as settled. Scrubbed clients are marked as such and taken out of
    matching entirely: they are never re-evaluated against the rollup they are
    in, and never considered for new ones.
- **Configurable window, global with per data source overrides.** The retention
  window is community configuration, with a floor of seven years and no
  ceiling. A community may retain longer but never shorter: a five year window
  is not a valid configuration. The floor is HUD's reporting compliance
  requirement, which a community cannot opt out of by shortening its window.
  One global window applies everywhere, overridden on individual data sources
  that need something different. The global window is the catch-all, held as
  the window on the warehouse data source itself, so a source client with no
  window of its own falls back to the destination's.
- **Three strategies.** A community selects how aged-out clients are handled:
  - **Hide**: conceal the client's PII everywhere the application presents it
    (screens, search, exports) while the records stay in the database exactly as
    they are. Nothing is overwritten, so Hide is reversible.
  - **Scrub**: destructively overwrite PII in the database, retaining the
    non-identifying structure for audit and reporting continuity. The original
    values are gone, not hidden.
  - **Delete**: remove the records outright.
- **Fields in scope.** One set of fields counts as PII, and both strategies act
  on it: Hide conceals them, Scrub overwrites them. At minimum that is first,
  middle, and last name and SSN. Scrub retains DOB, because household
  composition and age-based bucketing depend on it; fuzzing DOB to a consistent
  day within the month was considered and judged not worth the effort. Hide is
  under no such constraint, since concealing a value leaves it in place for the
  calculation. The full scope beyond that minimum is an open decision point
  below.
- **Every run is logged and reportable.** Each retention run records what it
  did. Each client identified as aged out, the strategy applied A community can
  report on this.
  - The log records client identifiers, never the PII that was scrubbed or
    deleted. A retention log that preserves the names it just cleared defeats
    the purpose.
  - Log entries outlive the records they describe. Under Delete the client row
    is gone, so entries keep plain identifying values (warehouse client id,
    data source, HUD `PersonalID`) rather than foreign keys to deleted rows.
  - The log is retained independently of the retention window: it is a record
    of platform action, not client data, and is not itself subject to aging out.
- **Backups are out of scope.** Scrubbing and deletion act on the live database
  only. Backups retain data for their own retention period. The customer-facing
  help text for the retention settings must state this.

This extends the PII strategy in ADR 0002 with the retention phase it does not
cover.

### Open decision points

These must be settled before implementation and recorded here on acceptance,
except where a point states that it is accepted as a limitation for now.

1. **Downstream systems.** Whether removal propagates to CAS and other
   integrations.
2. **How far the inventory departs from HUD's PPI definition.** We are not
   inventing a definition: the 2004 standards define PPI. A question is how
   we deviate from this definition.
   - **Narrower.** The working minimum is name and SSN. DOB is PPI and is
     deliberately kept for reporting, so the minimum already falls short of the
     definition on purpose.
   - **Wider.** HUD's list names no free text and nothing customer-defined,
     though both are potentially identifying. Categories to
     settle:
     - Client photos and uploaded files.
     - Contact information: phone, email, address, emergency contacts.
     - HMIS custom records — case notes, custom assessments, custom services —
       which carry free text that may name the client or third parties and is
       not structured enough to handle field by field.
     - Custom fields and other customer-defined data, whose contents the
       platform does not know in advance.

   Settling the inventory does not settle how far each strategy reaches into it.
   Hide can conceal all of it: nothing it hides is needed to compute a report,
   because the values stay in the database. Scrub may be more limited, for example
   leaving DOB if it still needs to serve for reporting. Scrub may employ hidden
   fields that it cannot easily overwrite.
3. **Visibility and matching under Hide.** Two questions the field inventory
   does not answer:
   - Whether an override exists for privileged roles, and whether using one is
     logged.
   - Whether a hidden client is still available for matching, which under Scrub
     they are not. Hide leaves the underlying data intact, so keeping them in
     matching is possible; whether it is wanted is the question.
4. **Definition of activity.** What counts as a record that keeps a client
   inside the retention window. Client-scoped aging depends on this definition.
   The obvious records are enrollments, services, exits, and the rest of the HUD
   data. But this may be too narrow. Data is collected about a client outside of
   any enrollment, and some of it is a reasonable signal that the client is still
   being worked with:
   - Uploaded files and client documents.
   - Notes and case notes.
   - Alerts.
   - Contact and referral activity recorded outside an enrollment. (CE data)

   This is a trade-off: the broader the definition, the fewer clients ever age out,
   and a definition wide enough to include incidental activity could keep a client
   indefinitely.
5. **Secondary copies of client data.** The HUD data is not the only place a
   client's PII lives. Each of these needs a retention decision:
   - **HUD report source data.** These tables hold names, SSN, and DOB
     directly. They are already archived and cleared on their own schedule, but
     the archives go to S3, so the PII moves rather than goes away.
   - **CSV loader and importer tables.** Expired automatically for recent
     importer versions only (2024+). Older versions (2022) may need to be purged
     by hand.
   - **Importer logs and errors.** Never purged, and rejected rows are kept as
     raw CSV text, so a failed import retains whole client records
     indefinitely.
   - **Files on S3.** Retained, with no expiration. This covers import source
     files and report archives alike. S3 is where PII the database has finished
     with tends to end up, so it needs a position of its own rather than being
     left to whichever feature wrote there.
   - **Version history.** Whole row snapshots of the versioned client models,
     never pruned and untouched by existing purges, so they outlive the records
     they describe.
   - **Activity logs.** Not ID-only, as is sometimes assumed: they record client
     names and the search terms staff typed, which include name, SSN, and DOB.
     Nothing purges them.
6. **Re-import of aged-out clients.** Accepted as a known limitation for the
   first phase; the durable fix open. Nothing stops a later import from
   bringing an aged-out client back. Routine imports carry only recently
   active clients, so in the normal case a expired client is not re-imported.
   The case that needs an answer is a full historical upload, say a ten year
   lookback: those clients import, then age out again on the next run. This might
   temporarily expose data for clients who have aged out, before the records are
   deleted. In the case of scrubbing, it might also create permanent duplicate
   records. We may need a marker recording that a client was aged out, checked on
   import so the record is skipped rather than recreated.

## Consequences

- **Positive:** Communities that want rolling cleanup can have it without
  imposing it on communities that do not.
- **Positive:** Hide is reversible, which neither other strategy is, and it
  gives communities a retention posture in the near term while Scrub and Delete
  are out of reach.
- **Positive:** The run log gives a community an answer to "what happened to
  this client's record," which is otherwise unrecoverable once data is deleted.
- **Negative:** Deletion and scrubbing are irreversible from within the
  application. Recovery is only possible from backups. Delete breaks report
  traceability for removed clients by design, which a community accepts when
  it selects it. Scrubbed records still count in historical reports, which may
  not match regenerated figures.
- **Negative:** A rollup is only as removable as its most recent source. A
  client active in one data source last year keeps their records in every other
  data source they appear in, however old, and a shorter window set on one of
  those data sources will not reach them. Over-retention is the deliberate
  trade for keeping rollups whole.
- **Negative:** Scrubbed clients retain DOB, so a scrubbed record is not fully
  de-identified. Communities selecting scrub accept this in exchange for
  reporting continuity.
- **Negative:** Hide leaves every byte of PII in the database. It does not
  satisfy a removal request, does not reduce what a breach or a database-level
  query would expose, and does not meet the 2004 HMIS Data & Technical
  Standards guidance.
- **Negative:** Removal from the live database does not remove data from
  backups. Customers who expect complete erasure must be told this.
- **Negative:** A community that wants a window shorter than seven years cannot
  have one. The floor takes that choice off the table.
- **Neutral:** Communities must act to move off the default.

## Alternatives Considered

- **Continue one-off manual removal only (status quo).** Rejected: each request
  is a bespoke engineering task with no shared procedure and no record of what
  was removed.
- **One retention period imposed by the platform.** Rejected: above the HUD
  floor, obligations differ by community and by data source. A single period
  would over-retain for some and under-retain for others, which is why the
  window is configurable and the global setting is a community's own default
  rather than ours.
- **Aging source clients individually.** Rejected: it would age out part of a
  rollup while the rest remains. Scrubbing a single source destroys the name and
  SSN its match was based on, so it would fall out of the rollup and reappear as
  a duplicate, and the destination's demographics would churn as sources dropped
  away one at a time. Holding the rollup together costs some over-retention and
  avoids all of it.
- **Automated rolling cleanup enforced by the platform.** Rejected: it is clear that
  communities need to turn this on and off and run it manually. Silent automated
  deletion is the wrong default for irreversible operations.
- **Delete as the only mechanism.** Rejected: hard deletion breaks the audit
  trail unconditionally, and some communities prefer scrubbing or hiding.
- **Per project type retention windows.** Rejected: it adds configuration
  surface and complicates client-scoped aging when a client spans project types
  with different windows. Data source scoping covers the known cases.
- **Crypto-shredding.** Encrypt PII per client and destroy the key to age out,
  which would also cover backups. Deferred: PII is stored in plaintext across
  many tables and the HUD models, so per-client encryption is a data model
  change well beyond this ADR. May be revisited once ADR 0002 phase 3 has
  consolidated PII storage.

## Additional Info

- Related: ADR [0002 (PII Management Strategy)](0002-pii-management-strategy.md).
- [2004 HMIS Data & Technical Standards](https://www.govinfo.gov/content/pkg/FR-2004-07-30/pdf/04-17097.pdf) §2.1.4, §4.2.2, §5.2.1.
