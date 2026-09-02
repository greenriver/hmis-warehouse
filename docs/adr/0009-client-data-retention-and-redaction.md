# ADR 0009: Client Data Retention and Removal

## Status

- Current Status: Proposed
- Date of last update: 2026-09-02
- Decision-makers: OP engineering team, OP support team

## Context

Two obligations pull in opposite directions. Auditability favours retaining
data so that any report figure stays traceable to the records that produced it.
Client privacy favours retaining the minimum PII for the minimum time. The
warehouse retains all ingested data indefinitely and has no provision for how
long client data is kept.

- HUD does not mandate a retention period. Customers set their own, and
  communities differ in legal obligations and local policy, so a single global
  rule does not fit.
- Removal of aged-out data is available as a one-off manual process today. The
  motivation for this ADR is customer demand and obligation to protect client
  data.
- Communities may make different choices on redaction, masking, or removal. There are
  real use cases for all three strategies.
- Communities may want different retention periods for different project types.
- Without a shared position, new data-retaining features may each approach the
  question differently.
- ADR [0002 (PII Management Strategy)](0002-pii-management-strategy.md) covers PII
  tracking, access control, and non-production anonymization, but not retention
  or removal of aged-out client data.

## Decision

Provide a per-community, opt-in client data retention capability that is user
configurable. The platform supplies the mechanism; the community decides if and
how it runs.

- **Opt-in and user-triggered.** Retention processing is off by default. A
  community may enable it, disable it, or run it on demand.
- **Client-scoped aging.** A client ages out only when none of their records
  fall inside the retention window. One service inside the window keeps all of
  that client's records, however old. Aging is never decided record by record.
- **Configurable window.** The retention window is community configuration with
  no fixed floor or ceiling. Seven years is a reference point, not a default
  the platform imposes. Windows may be set per project type.
- **Three strategies.** A community selects how aged-out clients are handled:
  - **Delete**: remove the records outright.
  - **Mask**: overwrite PII in place, retaining the non-identifying structure
    for audit and reporting continuity.
  - **Redact**: view-layer only redaction of sensitive fields.
- **Backups are out of scope.** Deletion and masking act on the live database
  only. Backups retain data for their own retention period. The customer-facing
  help text for the retention settings must state this.

This extends the PII strategy in ADR 0002 with the retention phase it does not
cover.

### Open decision points

These must be settled before implementation and recorded here on acceptance.

1. **Per project type windows.** Whether a community may set a different window
   per project type, or a single window per community. Per project type adds
   configuration surface and complicates client-scoped aging when a client
   spans project types with different windows.
2. **Fields affected by mask.** Which fields count as PII for masking. Whether
   the PII inventory from ADR 0002 is the authoritative list or a separate
   retention list is needed.
3. **Downstream systems.** Whether removal propagates to CAS and other
   integrations.
4. **Redact as a strategy.** Whether view-layer redaction belongs alongside
   delete and mask. It is the only reversible option, but PII remains in the
   database and it cannot answer a removal request.

## Consequences

- **Positive:** Communities that want rolling cleanup can have it without
  imposing it on communities that do not.
- **Negative:** Deletion and masking are irreversible from within the
  application. Recovery is only possible from backups. Delete breaks report
  traceability for removed clients by design, which a community accepts when
  it selects it. Masked records still count in historical reports, which may
  not match regenerated figures. Redaction is reversible and leaves PII in the
  database, so it does not satisfy a removal request on its own.
- **Negative:** Removal from the live database does not remove data from
  backups. Customers who expect complete erasure must be told this.
- **Neutral:** Communities must act to move off the default.

## Alternatives Considered

- **Continue one-off manual removal only (status quo).** Rejected: each request
  is a bespoke engineering task with no shared procedure and no record of what
  was removed.
- **A single global retention position.** Rejected: HUD leaves the period to
  customers, and obligations differ by community. One rule would over-retain
  for some and under-retain for others.
- **Automated rolling cleanup enforced by the platform.** Rejected: it is clear that
  communities need to turn this on and off and run it manually. Silent automated
  deletion is the wrong default for irreversible operations.
- **Delete as the only mechanism.** Rejected: hard deletion breaks the audit
  trail unconditionally, and some communities prefer masking.
- **Crypto-shredding.** Encrypt PII per client and destroy the key to age out,
  which would also cover backups. Deferred: PII is stored in plaintext across
  many tables and the HUD models, so per-client encryption is a data model
  change well beyond this ADR. May be revisited once ADR 0002 phase 3 has
  consolidated PII storage.

## Additional Info

- Related: ADR [0002 (PII Management Strategy)](0002-pii-management-strategy.md).
