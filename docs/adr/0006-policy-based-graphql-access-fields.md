# ADR 0006: Policy-Based GraphQL `access` Fields in HMIS

## Status

- Current Status: Accepted
- Date of last update: 2026-04-22
- Decision-makers: OP Engineering team

## Context

The HMIS GraphQL API exposes authorization for UI decisions through nested `access` objects (e.g. `client { access { canEditClient } }`). Historically these fields were built with `access_field` helpers that resolve **raw permissions** (`can`, `composite_perm`, `root_can`) or ad-hoc hashes (`def access` returning a `Hash`). That pushes composite rules and naming mismatches to the frontend; diverges from `Hmis::AuthPolicies::*`, where complex authorization is meant to live; and exposes permissions across data sources, which we need to avoid as we build out support for multi-HMIS installations.

We need a pattern that:

1. Exposes rules that map cleanly to UI decisions where possible.
2. Delegates to policy predicates.
3. Can be adopted gradually next to existing `access_field` usage.
4. Makes the mapping from policy methods to GraphQL fields obvious and maintainable.

## Decision

1. **Preferred pattern for new or migrated fields**: Inside an `access_field` block, use `Types::BaseAccess#bool_field` with a block that calls `policy_for(...)` and a policy predicate.

2. **Caching policy instances in the access object**: Use `define_method` on the access subclass to memoize helpers (e.g. `policy`, `global_policy`, or a domain-specific name like `referral_policy`), so multiple fields share one `policy_for` resolution per access object.

3. **Coexistence**: Legacy `can`, `composite_perm`, and `root_can` remain valid during migration. No requirement to rewrite all `access_field` blocks at once.

## Consequences

### Positive

- Standardize around using policy classes for permission checks across the application.
- Move away from faulty globally-scoped permissions, which aren't isolated across data sources.
- Stop duplicating permission logic in the frontend.
- Accommodate both simple policy checks and more complex checks using `bool_field` blocks.
- Performance: This approach adds a small number of additional database queries, because permission checks are scoped by data source through `Hmis::AuthPolicies::UserContext`. That change is necessary for correct multi–data-source behavior. Additional `bool_field` definitions on the same access object should not multiply query count as long as policies reuse memoized `policy` / `global_policy` / `UserContext` data; cost stays flat when new predicates read from already-loaded context.

### Negative / trade-offs

- Some GraphQL access blocks will temporarily mix legacy helpers and `bool_field` until migration completes.
- Performance / N+1 risk: Policy predicates must stay GraphQL-friendly: prefer `UserContext` memoization and existing preload hooks; avoid ad hoc queries or per-field work that bypasses shared caches. This is something to watch out for in policy design, not inherent to the `bool_field` approach.

## Alternatives Considered

1. **ActionPolicy `expose_authorization_rules` (GraphQL)**
  Useful in ecosystems that standardize on ActionPolicy end-to-end. Our stack uses custom `Hmis::AuthPolicies::*` and multi–data-source context; adopting the macro would not remove the need to bridge to our policies and naming, and GraphQL field naming conventions may not match without extra mapping.

3. **`policy_field` / `global_policy_field` on `BaseAccess`**
  Class-level macros that declare a Boolean field and resolve by calling a fixed `policy_for` pattern. Not chosen as the primary pattern: they are more declarative but less easily overrideable for fields that need AR loading, multiple policy types, or non-standard resources. `bool_field` with an explicit block stays flexible while still centralizing logic next to the field list. See draft: https://github.com/greenriver/hmis-warehouse/pull/6357

## Additional Info

- Reference implementation:  `HmisSchema::Organization`, `HmisSchema::Client` (partial as of 4/22/26).
