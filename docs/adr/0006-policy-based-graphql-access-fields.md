# ADR 0006: Policy-Based GraphQL `access` Fields in HMIS

## Status

- Current Status: Proposed
- Date of last update: 2026-04-22
- Decision-makers: OP Engineering team

## Context

The HMIS GraphQL API exposes authorization for UI decisions through nested `access` objects (e.g. `client { access { canEditClient } }`). Historically these fields were built with `access_field` helpers that resolve **raw permissions** (`can`, `composite_perm`, `root_can`) or ad-hoc hashes (`def access` returning a `Hash`). That pushes composite rules and naming mismatches to the frontend and diverges from `Hmis::AuthPolicies::*`, where complex authorization is meant to live.

We need a pattern that:

1. Exposes rules that map cleanly to UI decisions where possible.
2. Delegates to **policy predicates** instead of duplicating permission logic in GraphQL types.
3. Can be adopted **gradually** next to existing `access_field` usage.
4. Makes the mapping from policy methods to GraphQL fields obvious and maintainable.

## Decision

1. **Preferred pattern for new or migrated fields**: Inside an `access_field` block, use `Types::BaseAccess#bool_field` with a block that calls `policy_for(...)` and a policy predicate.

2. **Caching policy instances in the access object**: Use `define_method` on the access subclass to memoize helpers (e.g. `policy`, `global_policy`, or a domain-specific name like `referral_policy`), so multiple fields share one `policy_for` resolution per access object.

3. **Examples**: The following ruby sketch demonstrates the proposed shape.
```ruby
access_field do
  # Memoize policies for reuse
  define_method(:policy) { @policy ||= policy_for(object, policy_type: :hmis_client) }
  define_method(:global_policy) { @global_policy ||= policy_for(object.class, policy_type: :hmis_client) }

  # Instance policy (resource is the loaded record)
  bool_field(:can_view_client_name) { policy.can_view_name? }

  # Global (data-source–scoped) policy
  bool_field(:can_merge_clients) { global_policy.can_merge_clients? }

  # Different policy type
  bool_field(:can_view_referrals) do
    policy_for(Hmis::Ce::Referral, policy_type: :ce_referral).can_view_referrals?
  end

  # Complex logic, such as using an instance policy of a related record, or checking multiple different policies
  bool_field(:can_view_target_project) do
    related_record = load_ar_association(object, :something_else)
    another_policy = policy_for(related_record, policy_type: :something_else)
    another_policy.can_view?
  end
end
```

4. **Coexistence**: Legacy `can`, `composite_perm`, and `root_can` remain valid during migration. No requirement to rewrite all `access_field` blocks at once.

## Consequences

### Positive

- We standardize around using policy classes for permission checks across the application.
- Move away from faulty globally-scoped permissions, which aren't isolated across data sources.
- Frontend can rely on fewer “if A and B then hide” combinations, since policies encapsulate this logic.
- `bool_field` blocks allow simple policy checks, and are flexible to accommodate one-off complexity.

### Negative / trade-offs

- Some GraphQL access blocks will temporarily mix legacy helpers and `bool_field` until migration completes.
- Developers must know which `policy_type` and resource to pass to `policy_for`.

## Alternatives Considered

1. **ActionPolicy `expose_authorization_rules` (GraphQL)**
  Useful in ecosystems that standardize on ActionPolicy end-to-end. Our stack uses custom `Hmis::AuthPolicies::*` and multi–data-source context; adopting the macro would not remove the need to bridge to our policies and naming, and GraphQL field naming conventions may not match without extra mapping.

3. **`policy_field` / `global_policy_field` on `BaseAccess`**
  Class-level macros that declare a Boolean field and resolve by calling a fixed `policy_for` pattern. Not chosen as the primary pattern: they are more declarative but less easily overrideable for fields that need AR loading, multiple policy types, or non-standard resources. `bool_field` with an explicit block stays flexible while still centralizing logic next to the field list.

## Additional Info

- Reference implementation:  `HmisSchema::Organization`, `HmisSchema::Client` (partial as of 4/22/26).
