---
title: HMIS GraphQL authorization layers
summary: "The three authorization layers on HMIS GraphQL types (viewable_by scope, type-level authorized?, access_field/bool_field access objects), imperative mutation authorization with access_denied!, and the legacy helpers (can, permissions: kwarg, current_permission?) not to add."
area: authorization
tags: [authorization, graphql, hmis, viewable_by, authorized?, access_field, bool_field, BaseAccess, access_denied!, CleanBaseMutation, BaseMutation, permissions-kwarg, current_permission?, ADR-0006]
sources:
  - docs/adr/0006-policy-based-graphql-access-fields.md
  - drivers/hmis/app/graphql/types/base_object.rb
  - drivers/hmis/app/graphql/types/base_field.rb
  - drivers/hmis/app/graphql/types/base_access.rb
  - drivers/hmis/app/graphql/concerns/graphql_application_helper.rb
  - drivers/hmis/app/graphql/concerns/graphql_permission_checker.rb
  - drivers/hmis/app/graphql/mutations/clean_base_mutation.rb
  - drivers/hmis/app/graphql/mutations/base_mutation.rb
  - drivers/hmis/app/graphql/hmis_schema.rb
  - drivers/hmis/app/graphql/types/hmis_schema/organization.rb
  - drivers/hmis/app/graphql/mutations/delete_unit_group.rb
  - drivers/hmis/app/graphql/types/hmis_schema/client.rb
  - drivers/hmis/app/graphql/types/hmis_schema/project.rb
  - drivers/hmis/app/graphql/types/hmis_schema/enrollment.rb
  - drivers/hmis/app/graphql/types/hmis_schema/has_enrollments.rb
  - drivers/hmis/app/graphql/types/hmis_schema/root_query_access.rb
related:
  - authorization/hmis-permissions.md
  - hmis/graphql-layer.md
  - conventions/do-not-repeat.md
---

## Purpose

Where authorization checks belong in HMIS GraphQL schema code (`drivers/hmis/app/graphql/`). The RBAC model itself (roles, collections, `Hmis::AuthPolicies::*`, `policy_for`) is described in `authorization/hmis-permissions.md`; this doc covers the schema-side layers that call it: the `viewable_by` scope, type-level `self.authorized?`, field-level checks, `access` objects built from `bool_field`, and imperative `access_denied!` in mutations. It also names the legacy helpers (`Types::BaseAccess.can`, the `permissions:` kwarg on `Types::BaseField`, `current_permission?`) that still exist and must not be extended.

## Entry points

- `Model.viewable_by(user)`: scope on HMIS models (for example `Hmis::Hud::Project` in `drivers/hmis/app/models/hmis/hud/project.rb`, and `Hmis::Hud::Enrollment` via `drivers/hmis/app/models/hmis/hud/concerns/project_related.rb` / `enrollment_related.rb`). Apply it to every lookup and list so unauthorized and other-data-source rows are never loaded.
- `self.authorized?(object, ctx)`: class method overridden on a `Types::BaseObject` subclass. A false return is turned into a raised `GraphQL::UnauthorizedError` by `HmisSchema.unauthorized_object` (`drivers/hmis/app/graphql/hmis_schema.rb`).
- `access_field do ... end` on a type (`Types::BaseObject.access_field`, `drivers/hmis/app/graphql/types/base_object.rb`) builds an anonymous `Types::BaseAccess` subclass; inside it, `bool_field(:name) { policy.predicate? }` declares one Boolean field (`drivers/hmis/app/graphql/types/base_access.rb`).
- `Types::HmisSchema::RootQueryAccess` (`drivers/hmis/app/graphql/types/hmis_schema/root_query_access.rb`, GraphQL name `QueryAccess`): global, data-source-scoped flags such as `canManageForms`.
- `access_denied!` in a mutation `resolve` (`GraphqlApplicationHelper`, `drivers/hmis/app/graphql/concerns/graphql_application_helper.rb`) raises a plain `RuntimeError` with message `access denied`.
- `policy_for(resource, policy_type:)`: same helper module, delegates to `current_user.policy_for` (`drivers/hmis/app/models/hmis/user.rb`).
- `authorize_with:` kwarg on `Types::BaseField` (`drivers/hmis/app/graphql/types/base_field.rb`): a lambda `(user, object) -> Boolean` for field-level authorization. Unauthorized fields resolve to `nil` via `HmisSchema.unauthorized_field`.
- Schema-wide limits in `HmisSchema`: `max_depth 30`, `max_complexity 40_000`, introspection disabled outside development.

## How it works

Three layers, not interchangeable:

1. `viewable_by(user)` scope. Primary defense. Runs in SQL, so hidden rows never load and never affect counts or pagination.
2. `self.authorized?(object, ctx)`. Secondary guard on types that must not leak if a record slips past the scope. Returning false raises for the whole query (`HmisSchema.unauthorized_object`); it is not a filter. Add it on sensitive or traversal-opening types (`Client`, `Project`, `Enrollment`, `CeReferral`), not on small nested types whose parent is already authorized.

```ruby
# drivers/hmis/app/graphql/types/hmis_schema/client.rb
def self.authorized?(object, ctx)
  super && ctx[:current_user].policy_for(object, policy_type: :hmis_client).can_view?
end
```

3. Per-field checks. Default form: check a memoized policy in the resolver and return `[]`/`nil`.

```ruby
field :alerts, [HmisSchema::ClientAlert], null: false

def alerts
  return [] unless policy.can_view_alerts?

  load_ar_association(object, :active_alerts).sort_by(&:created_at).reverse
end
```

Two-level access (summary vs. details, as on `Types::HmisSchema::Enrollment`) uses field-level authorization so extra fields null out without a resolver each; for a new case use `authorize_with:` on the field, not the deprecated `permissions:` kwarg.

Access objects are presentational: the frontend reads `client { access { canEditClient } }` to decide what to show. They are not a security boundary, so each flag should call the same policy predicate the mutation or resolver uses (ADR 0006). Worked example, `drivers/hmis/app/graphql/types/hmis_schema/organization.rb`:

```ruby
access_field do
  define_method(:policy) { @policy ||= policy_for(object, policy_type: :hmis_organization) }

  bool_field(:can_delete_organization) { policy.can_delete? }
  bool_field(:can_edit_organization) { policy.can_edit? }
end
```

Mutations authorize imperatively: subclass `Mutations::CleanBaseMutation`, load through `viewable_by(current_user)`, then `access_denied!` unless found and the policy predicate passes. Worked example, `drivers/hmis/app/graphql/mutations/delete_unit_group.rb`:

```ruby
unit_group = Hmis::UnitGroup.viewable_by(current_user).find_by(id: id)

access_denied! unless unit_group.present?
access_denied! unless current_user.policy_for(unit_group.project, policy_type: :hmis_project).can_manage_units?
```

Global questions ("can this user do X anywhere in the current data source?") pass a class to `policy_for` and belong on `RootQueryAccess`, navigation, or `can_create?` checks; never use one to authorize a specific record.

## Key files

- `drivers/hmis/app/graphql/types/base_object.rb:106` `self.access_field`, builds the access type and resolves it to `object`.
- `drivers/hmis/app/graphql/types/base_access.rb:29` legacy `self.can`; `:43` `self.bool_field` (requires a block, strips a trailing `?`).
- `drivers/hmis/app/graphql/types/base_field.rb:46` `authorized?`: `permissions:` path routes to `GraphqlPermissionChecker`, `authorize_with:` calls the lambda.
- `drivers/hmis/app/graphql/concerns/graphql_application_helper.rb:25` `access_denied!`; `:29` `policy_for`; `:37` legacy `current_permission?`; `:52` `load_ar_client_association` (preloads client auth dependencies).
- `drivers/hmis/app/graphql/concerns/graphql_permission_checker.rb:15` `current_permission_for_context?`: raw-permission check; `:40` refuses when the entity's data source is not `current_user.hmis_data_source_id`.
- `drivers/hmis/app/graphql/hmis_schema.rb:60` `unauthorized_object` raises; `:65` `unauthorized_field` returns nil.
- `drivers/hmis/app/graphql/mutations/clean_base_mutation.rb:11` `< GraphQL::Schema::Mutation`; `drivers/hmis/app/graphql/mutations/base_mutation.rb:12` legacy `< GraphQL::Schema::RelayClassicMutation`.
- `drivers/hmis/app/graphql/types/hmis_schema/organization.rb:34` `bool_field` example.
- `drivers/hmis/app/graphql/mutations/delete_unit_group.rb:16` `viewable_by` + `access_denied!` example.
- `drivers/hmis/app/graphql/types/hmis_schema/client.rb:32`, `project.rb:36`, `enrollment.rb:30` `self.authorized?` overrides; `enrollment.rb:43` `self.field` override and `:53` `summary_field` (two-level access).
- `drivers/hmis/app/graphql/types/hmis_schema/has_enrollments.rb:27` `after_paginate` preload.
- `docs/adr/0006-policy-based-graphql-access-fields.md` decision record for `bool_field`.

## Gotchas

- Relying on `self.authorized?` without `viewable_by` does not filter: the scope still loads and counts hidden rows, and the first one that fails `authorized?` raises `GraphQL::UnauthorizedError` for the whole query. `authorized?` is a guard against leakage, never a list filter.
- `viewable_by` answers visibility only. Edit and delete in a mutation still need `policy_for(...).can_x?`.
- Global policies (`policy_for(SomeClass, policy_type: ...)`) say the user could act somewhere in the data source. Using one on a specific record grants access the user may hold only at another project.
- `access_denied!` raises `RuntimeError`, not a GraphQL error type; do not `rescue` it in a mutation.
- Policy checks on a page of nodes N+1 unless dependencies are preloaded. Paginated fields pass `after_paginate` to call `policy_context.preload_project_dependencies` / `preload_client_dependencies` / `preload_referral_dependencies` on the resolved page; the `Has*` concerns (`has_enrollments.rb`, `has_projects.rb`, `has_clients.rb`, `has_ce_referrals.rb`) already do this. In resolvers, read associations with `load_ar_association` / `load_ar_client_association`. See `hmis/graphql-layer.md`.
- Several `Has*` helpers accept `dangerous_skip_permission_check` so a parent that already authorized (for example `Project`) can skip a second scope. Do not add a skip without a parent check.
- Nesting a full `Project`/`Client`/`Enrollment` type on a config or summary object opens traversal to the rest of that graph. Expose scalars (`project_name`, `project_id`) when that is all the UI needs.
- `GraphqlPermissionChecker` refuses any entity outside `current_user.hmis_data_source_id`, but it resolves raw permission flags rather than policy requirements; that is why it is legacy.
- The `permissions:` kwarg is still live in one place, `Types::HmisSchema::Enrollment` (`self.field` override and `access_field permissions: nil`). Do not copy that into a new type.

## Do not repeat

Repo-wide entries: `conventions/do-not-repeat.md` 13 (`BaseMutation`) and 14 (raw-permission access helpers).

- `class Foo < BaseMutation` (`drivers/hmis/app/graphql/mutations/base_mutation.rb`, Relay-classic scaffolding). Instead: `< CleanBaseMutation` (`drivers/hmis/app/graphql/mutations/clean_base_mutation.rb`), for example `drivers/hmis/app/graphql/mutations/delete_unit_group.rb`.
- `permissions: :can_x` on a `field` (`drivers/hmis/app/graphql/types/base_field.rb:46`). Instead: a policy check in the resolver, or `authorize_with:` for two-level access.
- `current_permission?(permission:, entity:)` (`drivers/hmis/app/graphql/concerns/graphql_application_helper.rb:37`). Instead: `policy_for(entity, policy_type: ...).can_x?`.
- `can :x` inside `access_field` (`drivers/hmis/app/graphql/types/base_access.rb:29`, still used in `project.rb` and `assessment.rb`). Instead: `bool_field(:can_x) { policy.can_x? }`, for example `drivers/hmis/app/graphql/types/hmis_schema/organization.rb`.
- `composite_perm` and `root_can` are named in ADR 0006 but no longer exist; do not reintroduce them.

## Related

- `authorization/hmis-permissions.md`: roles, collections, `Hmis::AuthPolicies::*`, `policy_for`, `UserContext`.
- `hmis/graphql-layer.md`: dataloader, pagination, `after_paginate`, N+1 testing.
- `conventions/do-not-repeat.md`: entries 13 and 14.
- `docs/adr/0006-policy-based-graphql-access-fields.md`: why `bool_field` replaced raw-permission helpers.
