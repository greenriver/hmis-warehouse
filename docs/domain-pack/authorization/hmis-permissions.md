---
title: HMIS permissions and policies
summary: "The HMIS (drivers/hmis) permission model: Hmis::AccessControl joins Hmis::Role, Hmis::AccessGroup (shown as Collection in the UI), and Hmis::UserGroup, always scoped to the user's HMIS data source. Covers permission requirements, instance vs global policies, UserContext, and viewable_by scopes."
area: authorization
tags: [authorization, hmis, Hmis::AccessControl, Hmis::Role, Hmis::AccessGroup, Collection, Hmis::UserGroup, UserContext, ResourcePolicy, viewable_by, hmis_data_source_id, permission-requirements]
sources:
  - drivers/hmis/app/models/hmis/access_control.rb
  - drivers/hmis/app/models/hmis/role.rb
  - drivers/hmis/app/models/hmis/access_group.rb
  - drivers/hmis/app/models/hmis/user_group.rb
  - drivers/hmis/app/models/hmis/user_group_member.rb
  - drivers/hmis/app/models/hmis/group_viewable_entity.rb
  - drivers/hmis/app/models/hmis/project_access_group_member.rb
  - drivers/hmis/app/models/hmis/base_access_loader.rb
  - drivers/hmis/app/models/hmis/auth_policies/base_policy.rb
  - drivers/hmis/app/models/hmis/auth_policies/resource_policy.rb
  - drivers/hmis/app/models/hmis/auth_policies/user_context.rb
  - drivers/hmis/app/models/hmis/auth_policies/hmis_project_policy.rb
  - drivers/hmis/app/models/hmis/auth_policies/hmis_client_policy.rb
  - drivers/hmis/app/models/hmis/auth_policies/hmis_enrollment_policy.rb
  - drivers/hmis/app/models/hmis/auth_policies/hmis_organization_policy.rb
  - drivers/hmis/app/models/hmis/auth_policies/ce_referral_policy.rb
  - drivers/hmis/app/models/hmis/auth_policies/context_loaders/hmis_project_access_group_loader.rb
  - drivers/hmis/app/models/hmis/user.rb
  - drivers/hmis/app/models/hmis/auth_policies/context_loaders/hmis_permission_loader.rb
related:
  - authorization/hmis-graphql-authorization.md
  - authorization/warehouse-access-controls.md
  - hmis/restricted-records-and-multi-hmis.md
---

## Purpose

How the HMIS (`drivers/hmis`) decides what a user may see and do. The HMIS permission system is
structurally similar to warehouse Access Controls but entirely separate: its own tables
(`hmis_roles`, `hmis_access_groups`, `hmis_access_controls`, `hmis_user_groups`), its own models
under `Hmis::`, and its own policy classes under `Hmis::AuthPolicies`. There is no legacy path:
every grant is an `Hmis::AccessControl`, and every check is additionally scoped to the data source
the user is signed into (`Hmis::User#hmis_data_source_id`, a request-scoped `attr_accessor`).

Read this doc before adding a permission, a policy predicate, a `viewable_by` scope, or any code
that asks whether an HMIS user may do something. The GraphQL-layer conventions (where `viewable_by`,
`authorized?`, and access objects go) are in `authorization/hmis-graphql-authorization.md`.

## Entry points

- `user.policy_for(resource, policy_type:)` on `Hmis::User` (memoized). `policy_type: :hmis_project`
  resolves to `Hmis::AuthPolicies::HmisProjectPolicy`; the class is
  `"Hmis::AuthPolicies::#{policy_type.to_s.camelize}Policy"`. Passing a record returns the
  `Instance` policy; passing a class returns the `Global` policy.
  `user.policy_for(project, policy_type: :hmis_project).can_view_enrollment_details?`
- `Hmis::Hud::Project.viewable_by(user)`, `Hmis::Hud::Client.viewable_by(user)` (alias of
  `visible_to`), `Hmis::Hud::Enrollment.viewable_by(user, include_limited_access_enrollments: false)`.
  Use these to load records; they enforce data-source scope and Collection reach.
- `Hmis::Hud::Project.with_access(user, *permissions, mode: :any)`: projects where the user holds
  the named permissions with requirements resolved. Name only the permission you need.
- `Hmis::AuthPolicies::UserContext`, reached as `user.policy_context` (memoized). Provides
  `project_permissions(project_id)`, `client_permissions(client_id)`,
  `organization_permissions(organization)`, `global_permissions`,
  `project_ids_with_permissions(*perms, mode:)`, and `preload_*_dependencies` for batches.
- `Hmis::Role.permissions_with_descriptions`: the single definition of every permission and its
  metadata. `Hmis::Role.ensure_permissions_exist` adds missing columns; call it from a migration
  after adding a key.
- HMIS admin UI lives under `HmisAdmin::` controllers in `drivers/hmis/app/controllers/hmis_admin/`,
  gated by `require_hmis_admin_access!` (`app/controllers/concerns/enforce_hmis_enabled.rb`).

## How it works

A grant is one `Hmis::AccessControl` row joining one `Hmis::Role` (what), one Collection
(`Hmis::AccessGroup`, which entities), and one `Hmis::UserGroup` (who). `Hmis::User` reaches
grants `has_many :access_controls, through: :user_groups`; membership rows are
`Hmis::UserGroupMember`.

A Collection (`Hmis::AccessGroup`) holds `Hmis::GroupViewableEntity` rows (`collection_id`,
polymorphic `entity`) for Data Sources, Organizations, Projects, and `Hmis::ProjectGroup`s.
Coverage is inclusive: a project is covered when it, its organization, its data source, or a
project group containing it is listed (`GroupViewableEntity.includes_entity`). The database view
`Hmis::ProjectAccessGroupMember` flattens this to `(project_id, access_group_id)` pairs for
`Hmis::AuthPolicies::ContextLoaders::HmisProjectAccessGroupLoader`. Coverage grants nothing on its
own; the attached Role must grant the permission.

`Hmis::Role` stores each permission as a boolean column on `hmis_roles` (61 permissions today).
`permissions_with_descriptions` carries `description`, `administrative`, `access`
(`:viewable`/`:editable`), `category`/`sub_category`, `global`, and `requirements`. Declare only
direct requirements; `Hmis::Role.required_permissions_for(permission)` walks the chain recursively
and raises on a cycle. `Hmis::AuthPolicies::ContextLoaders::HmisPermissionLoader` unions
`granted_permissions` across the user's roles reaching the given access group ids, then drops any
permission whose full chain is not present. An unmet requirement makes the permission absent, so
every policy predicate behaves as if it was never granted.

Policies subclass `Hmis::AuthPolicies::ResourcePolicy` and nest two `Hmis::AuthPolicies::BasePolicy`
subclasses. `Instance` (resource is a record) reads `context.project_permissions(...)` or
`client_permissions(...)`, so requirements and data-source scope apply per record; use it to
authorize an action on a record. `Global` (resource is a class) reads `context.global_permissions`,
the union over every access group reaching any entity in the current data source; use it for
navigation, `can_create?` before a record exists, or short-circuiting a scope. `global_permissions`
can over-report when a requirement chain is split across projects, so it must never authorize a
specific record. `ResourcePolicy.for_resource` picks the variant by `resource.is_a?(Class)` and
raises `NotImplementedError` when the nested class is missing.

`UserContext` is per user per request (`Hmis::User#policy_context` and `policy_for` are memoized).
`project_permissions` returns an empty set and reports to Sentry when the project is not in the
user's data source. Context loaders cache lookups; `preload_project_dependencies`,
`preload_client_dependencies`, and `preload_referral_dependencies` batch them for a page of records.

Standard pattern for acting on one record:

```ruby
record = Hmis::Hud::Project.viewable_by(current_user).find_by(id: id)
access_denied! unless record && current_user.policy_for(record, policy_type: :hmis_project).can_delete?
```

## Key files

- `drivers/hmis/app/models/hmis/access_control.rb`: the grant; `entity_name`, `describe_changes`, `filtered` scope.
- `drivers/hmis/app/models/hmis/role.rb`: `permissions_with_descriptions`, `grants?`, `required_permissions_for`, `ensure_permissions_exist`, `with_permissions` scope.
- `drivers/hmis/app/models/hmis/access_group.rb`: Collection; `set_viewables`, `add_viewable`, `contains_with_inherited`.
- `drivers/hmis/app/models/hmis/user_group.rb`, `user_group_member.rb`: who receives a grant; `add`/`remove` keep paper_trail rows.
- `drivers/hmis/app/models/hmis/group_viewable_entity.rb`: `includes_entity`, `includes_any_entity_in_data_source`.
- `drivers/hmis/app/models/hmis/project_access_group_member.rb`: DB view of project to access group, direct and inherited.
- `drivers/hmis/app/models/hmis/base_access_loader.rb`: `fetch_one(entity, permission)` behind `can_x_for?`; raw role match, no requirements.
- `drivers/hmis/app/models/hmis/auth_policies/base_policy.rb`, `resource_policy.rb`: policy base and Instance/Global selector.
- `drivers/hmis/app/models/hmis/auth_policies/user_context.rb`: permission sets, data-source checks, loader memoization.
- `drivers/hmis/app/models/hmis/auth_policies/context_loaders/hmis_permission_loader.rb`: requirement resolution.
- `drivers/hmis/app/models/hmis/auth_policies/context_loaders/hmis_project_access_group_loader.rb`: project to access group ids.
- `drivers/hmis/app/models/hmis/auth_policies/hmis_project_policy.rb`, `hmis_client_policy.rb`, `hmis_enrollment_policy.rb`, `hmis_organization_policy.rb`, `ce_referral_policy.rb`: worked examples of Instance and Global.
- `drivers/hmis/app/models/hmis/user.rb`: `policy_for`, `policy_context`, `hmis_data_source_id`, generated `can_*` methods.

## Gotchas

- `Hmis::User#can_x`, `can_x?`, `permission?`, `permissions?` answer "anywhere, in any data source"
  from `load_effective_permissions`. `can_x_for?(entity)` and `permissions_for?` are entity-scoped
  through `Hmis::BaseAccessLoader` subclasses but match Role columns directly, so they skip
  requirement resolution. Both bypass `hmis_data_source_id`. Use a policy predicate.
- `Hmis::User#entities_with_permissions` (behind `viewable_projects` and `Project.viewable_by`)
  also matches Role columns directly. `Project.with_access` resolves requirements; prefer it for
  anything project-scoped that names a permission other than `can_view_project`.
- The class is `Hmis::AccessGroup`, the table `hmis_access_groups`, the `GroupViewableEntity`
  foreign key `collection_id`, the admin UI "Collection". A rename is pending; write
  "Collection (`Hmis::AccessGroup`)" in prose and "Collection" in any user-facing text.
- `viewable_by` is the primary guard for loading records. An `authorized?` or policy check on an
  already-loaded record authorizes the action, not the lookup, and cannot stop a record from
  another data source from being found. Detail in `authorization/hmis-graphql-authorization.md`.
- `UserContext.new` raises unless the user is an `Hmis::User` with `hmis_data_source_id` set. In
  specs and jobs, assign it before calling `policy_for`.
- Caching is request-scoped, so permission changes take effect on the next request. The one
  exception is `Hmis::User#cached_viewable_project_ids` (private), which uses `Rails.cache` for one
  minute.
- `Hmis::UserGroup` includes `UserPermissionCache` and calls the warehouse `User.clear_cached_permissions`
  on save; that is the warehouse cache, not the HMIS `UserContext`.
- `Hmis::GroupViewableEntity` and `Hmis::ProjectAccessGroupMember` inherit from
  `GrdaWarehouseBase`; `Hmis::AccessGroup`, `Hmis::Role`, `Hmis::AccessControl`, and
  `Hmis::UserGroup` inherit from `ApplicationRecord`. Joins across them cross a database boundary,
  which is why `HmisProjectAccessGroupLoader` filters deleted access groups in Ruby.

## Do not repeat

- `user.can_view_clients?` or any generated `can_*?` / `can_*_for?` flag in app code. Replace with
  an instance policy (`user.policy_for(client, policy_type: :hmis_client).can_view?`) or, for
  "anywhere in this data source", a global policy (`user.policy_for(Hmis::Hud::Client, policy_type: :hmis_client).can_view?`).
  Legacy callers remain in `drivers/hmis/app/models/hmis/user.rb` (`permission_for?`).
- Loading a record with `find` and checking a policy afterwards. Replace with
  `Model.viewable_by(user).find_by(id:)` then the policy check.
- Propagating the `AccessGroup` name into new user-facing text, GraphQL field names, or docs.
  Write "Collection".
- Declaring a transitive requirement in `permissions_with_descriptions`
  (`requirements: [:can_view_enrollment_details, :can_view_project, :can_view_clients]`). Declare the
  direct requirement only; resolution is recursive.
- Raw-permission GraphQL helpers (`can`, `permissions:` kwarg, `current_permission?`) are entry 14
  in `conventions/do-not-repeat.md`.

## Related

- `authorization/hmis-graphql-authorization.md`: where `viewable_by`, `authorized?`, access
  objects, and `access_denied!` go in the GraphQL layer.
- `authorization/warehouse-access-controls.md`: the parallel warehouse model (`AccessControl`,
  `Collection`, `UserGroup`).
- `hmis/restricted-records-and-multi-hmis.md`: `hmis_data_source_id` binding and restricted-client
  PII redaction (`UserContext#pii_redacted_for_client?`).
- `conventions/do-not-repeat.md`: entries 13 and 14.
- Human-facing source docs: `docs/features/hmis/hmis-permissions.md`,
  `docs/features/hmis/hmis-auth-policies.md`, `docs/adr/0006-policy-based-graphql-access-fields.md`.
