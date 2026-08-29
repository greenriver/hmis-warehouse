# ADR 0009: Client Data Retention and Redaction Position

## Status

- Current Status: Proposed
- Date of last update: 2026-08-29
- Decision-makers: OP engineering team

## Context

The platform holds two quality goals in tension. Data Integrity & Auditability
(Goal 2) favours retaining data so that any report figure stays traceable to the
records that produced it. Client Protection & Fair Access (Goal 3) favours
retaining the minimum PII for the minimum time. The source-preserving warehouse
currently leans toward retention by default, and no position states how long
client data is kept or what happens when it must be withdrawn.
[Section 1.2](../architecture/01-introduction.md).

- There is no stated retention or redaction position, so a client erasure request
  has no clean answer that also preserves the audit trail.
- The appropriate position varies by community — legal obligations and local
  policy differ across CoCs and customers — so a single global rule does not fit.
- Without a shared position, new data-retaining features may each approach the
  question differently.
- ADR [0002 (PII Management Strategy)](0002-pii-management-strategy.md) covers PII
  tracking, access control, and non-production anonymization, but not retention,
  erasure, or redaction of aged-out client data.

## Decision

Establish a per-community client data retention and redaction position, enforced
by the platform rather than decided ad hoc per feature.

- Client data is **marked once it ages out** of its community's retention window.
- Each community selects a **strategy applied to aged-out records**:
  - **Prune** — remove the records outright.
  - **Scrub** — remove or overwrite the PII in place, retaining the
    non-identifying structure for audit continuity.
  - **View-layer redaction** — retain the records but withhold PII at the
    presentation layer.
- The retention window and strategy are community-scoped configuration, defaulting
  to the current retain-everything behaviour where a community has stated no
  policy, so existing deployments are unaffected until they opt in.

This extends the PII strategy in ADR 0002 with the retention phase it does not
cover.

## Consequences

- **Positive:** A client erasure request has a defined answer that a community can
  satisfy without silently breaking its audit trail. The retention-vs-privacy
  question is answered once, in configuration, rather than re-litigated per
  feature. Storage growth (R-6) is bounded as a side effect of pruning.
- **Negative:** Scrub and prune are irreversible; a mis-set retention window
  destroys data that cannot be recovered from within the application. Audit
  continuity depends on the chosen strategy — pruning breaks traceability for the
  removed records by design, which a community accepts when it selects it.
- **Neutral:** Communities must state a retention policy to move off the default;
  the platform carries all three strategies regardless of which a given community
  uses.

## Alternatives Considered

- **A single global retention position.** Rejected: legal and policy obligations
  differ by community, so one rule would either over-retain for privacy-strict
  communities or under-retain for audit-strict ones.
- **Delete rather than redact on erasure.** Rejected as the only mechanism:
  hard deletion breaks the audit trail unconditionally, which some communities
  cannot accept; redaction and scrub preserve auditability where required.
- **Leave it unresolved (status quo).** Rejected: the retain-everything default
  answers the privacy obligation silently in favour of retention and leaves
  erasure requests unanswerable.

## Additional Info

- Related: ADR [0002 (PII Management Strategy)](0002-pii-management-strategy.md).
