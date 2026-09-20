---
title: Warehouse Access Controls (ACLs)
summary: "The current warehouse permission model: AccessControl joins a Role, a Collection of entities, and a UserGroup. Explains how a user's effective permissions and viewable entities are resolved, including EnrollmentArbiter and permission-cache invalidation."
area: authorization
tags: [authorization, acl, AccessControl, Collection, UserGroup, GroupViewableEntity, EntityAccess, EnrollmentArbiter, viewable_by, permission-cache]
sources:
  - app/models/access_control.rb
  - app/models/collection.rb
  - app/models/user_group.rb
  - app/models/user_group_member.rb
  - app/models/grda_warehouse/group_viewable_entity.rb
  - app/models/concerns/entity_access.rb
  - app/models/concerns/user_permission_cache.rb
  - app/models/user.rb
  - drivers/client_access_control/app/models/client_access_control/enrollment_arbiter.rb
  - app/controllers/admin/access_controls_controller.rb
  - app/controllers/admin/collections_controller.rb
  - app/controllers/admin/user_groups_controller.rb
  - app/models/grda_warehouse/hud/project.rb
  - app/models/concerns/user_concern.rb
related:
  - authorization/warehouse-legacy-roles.md
  - authorization/warehouse-policies.md
  - roi/roi-authorizations-and-visibility.md
---

## Purpose

The warehouse's current permission model. A grant is one `AccessControl` row binding a `Role`
(what actions), a `Collection` (which entities), and a `UserGroup` (which users). A user holds
every grant reachable through their user groups. This is the path a user takes when
`User#using_acls?` is true (`permission_context == 'acls'`, defined in
`app/models/concerns/user_concern.rb`); users still on `role_based` take the legacy path
described in `authorization/warehouse-legacy-roles.md`.

The code calls this the "ACL" system and the model is `AccessControl`, but structurally it is
role-based access control with entity scoping. Unlike the legacy system, one user can hold
different permission levels on different entities, because each `AccessControl` carries its own
role and its own collection.

Use this doc when adding a permission-gated feature, adding a new kind of entity that must be
scoped, or debugging why a user does or does not see a project, cohort, report, or client.

## Entry points

- `user.policy_for(record)` (`app/models/user.rb`): the preferred check for one resource.
  Builds `record.policy_class` with a `policy_context`, which is `UserAclContext` or
  `UserLegacyContext` depending on `using_acls?`. Details in `authorization/warehouse-policies.md`.
- `Model.viewable_by(user, permission: :can_x)`: the scope for "which records may this user
  see". Defined per entity type: `GrdaWarehouse::Hud::Project`, `GrdaWarehouse::Hud::Organization`,
  `GrdaWarehouse::DataSource`, `GrdaWarehouse::Cohort`, `GrdaWarehouse::ProjectGroup`,
  `GrdaWarehouse::WarehouseReports::ReportDefinition`. Most also define `editable_by(user)`.
  `permission:` is honored only on the ACL branch.
- `user.collections_for_permission(:can_x)` (`app/models/user.rb`): collection ids from the
  user's access controls whose role has that flag. Every `viewable_by` scope above resolves
  entity ids from these collections through `GrdaWarehouse::GroupViewableEntity`.
- `user.can_x?`: generated per `Role.permissions`; merges flags across the user's roles with no
  entity scope. Answers "anywhere?", not "on this record?".
- `ClientAccessControl::EnrollmentArbiter` (`drivers/client_access_control/`): client and
  enrollment visibility. Public methods: `clients_destination_visible_to`,
  `clients_source_visible_to`, `clients_source_searchable_to`, `enrollments_visible_to`,
  `clients_destination_or_source_visible_to`.
- `EntityAccess#replace_access(users, scope: :viewer | :editor)` and
  `users_with_access(access_type:)`: per-entity access on cohorts, project groups, and data
  sources.
- Admin UI: `Admin::AccessControlsController`, `Admin::CollectionsController`,
  `Admin::UserGroupsController`, `Admin::RolesController`.

## How it works

**Grant.** `AccessControl` (`app/models/access_control.rb`) `belongs_to :collection, :role,
:user_group` and validates all three present. `User has_many :access_controls, through:
:user_groups` and `has_many :roles, :collections, through: :access_controls`.

**Collection.** `Collection` (`app/models/collection.rb`) owns
`GrdaWarehouse::GroupViewableEntity` rows (`app/models/grda_warehouse/group_viewable_entity.rb`),
a polymorphic join on `(collection_id, entity_type, entity_id)`. Entity types: `DataSource`,
`Hud::Organization`, `Hud::Project`, `ProjectAccessGroup`, `Lookups::CocCode`,
`WarehouseReports::ReportDefinition`, `ProjectGroup`, `Cohort`, and `HmisSupplemental::DataSet`.
`collection_type` (`Projects`, `Project Groups`, `Reports`, `Cohorts`, `Supplemental Data Sets`)
limits which types the admin UI offers; see `Collection#relevant_entity_types`. Project access is
inclusive: `Project.project_ids_viewable_by` unions ids from directly listed projects, their
organizations, data sources, CoC codes, and project access groups. `Collection#set_viewables`
replaces membership, restoring soft-deleted rows rather than inserting duplicates.

**System collections.** `Collection.maintain_system_groups` keeps the "All ..." collections,
"Window Data Sources", and the "Hidden System Group" in sync with every record of each type, and
binds the hidden group to `Role.system_user_role` and `UserGroup.system_user_group`. `system` is
an array column; `['Entities']` locks membership (`entities_locked?`), `'Hidden'` hides it.

**Per-entity access.** `EntityAccess` (`app/models/concerns/entity_access.rb`), included by
`GrdaWarehouse::Cohort`, `GrdaWarehouse::ProjectGroup`, and `GrdaWarehouse::DataSource`, lazily
creates for one record: a system `Collection` with `source: self` holding only that record, a
viewable and an editable system `UserGroup` (`context: :viewable | :editable`), system `Role`s
with the one flag, and two `AccessControl`s. `replace_access` swaps members of one user group.
`remove_system_collections!` tears them down on delete.

**Arbiter.** `EnrollmentArbiter` combines three sources on the ACL branch: enrollments at
projects in `Project.viewable_by(user, permission: :can_view_clients)`, enrollments of clients
with an active confirmed ROI in the user's CoCs at projects viewable under
`:can_view_client_enrollments_with_roi`, and clients in authoritative data sources
`directly_viewable_by` the user. Search uses `:can_search_own_clients` and
`:can_search_clients_with_roi` instead. Every public method branches on `using_acls?`.

**Caching.** `collections_for_permission`, `viewable_project_ids`, and `editable_project_ids`
read `Rails.cache` with a 5-minute expiry (`User::EXPIRY_MINUTES`), bypassed in the test
environment. `UserPermissionCache` (`app/models/concerns/user_permission_cache.rb`), included by
`AccessControl`, `Collection`, `UserGroup`, and `Role`, runs `after_save
:invalidate_user_permission_cache`, which calls `User.clear_cached_permissions` and deletes every
`user_permissions*` key (project id keys share that prefix). `@permissions`,
`@ids_for_relations`, and the `memoize`d `policy_for`, `policy_context`, and
`viewable_project_ids` live on the `User` instance and last one request.

## Key files

- `app/models/access_control.rb`: the grant; `system`, `user_managed`, `not_system`, `filtered`
  scopes; `system?`, `name`.
- `app/models/collection.rb`: entity associations through `group_viewable_entities`,
  `collection_type` rules, `set_viewables`, `add_viewable`, `remove_viewable`,
  `maintain_system_groups`, `system_collections`, `destroy_with_associated_records!`.
- `app/models/user_group.rb`: `system_user_group`, `add`/`remove` (one query per user for
  paper_trail; queues `populate_external_reporting_permissions!`).
- `app/models/user_group_member.rb`: join row; `describe_changes` for audit history.
- `app/models/grda_warehouse/group_viewable_entity.rb`: polymorphic join; `collection_id` on the
  ACL path, `access_group_id` on the legacy path (`set_viewables` writes `access_group_id = 0`).
- `app/models/concerns/entity_access.rb`: `replace_access`, `system_collection`,
  `viewable_access_control`, `editable_access_control`, `users_with_access`,
  `remove_system_collections!`.
- `app/models/concerns/user_permission_cache.rb`: `invalidate_user_permission_cache`.
- `app/models/user.rb`: `load_effective_permissions`, generated `can_x?` methods and `User.can_x`
  scopes, `collections_for_permission`, `viewable_project_ids`, `editable_project_ids`,
  `clear_cached_permissions`, `ids_for_relations`, `policy_for`, `policy_context`.
- `app/models/grda_warehouse/hud/project.rb`: `viewable_by`, `viewable_by_entity`,
  `editable_by`, `project_ids_viewable_by` and the `project_ids_from_*` helpers.
- `drivers/client_access_control/app/models/client_access_control/enrollment_arbiter.rb`: client
  and enrollment visibility.
- `app/controllers/admin/access_controls_controller.rb` (`AccessControl.user_managed`,
  `require_can_edit_users!`), `app/controllers/admin/collections_controller.rb`
  (`Collection.general`, `require_can_edit_collections!`),
  `app/controllers/admin/user_groups_controller.rb` (`UserGroup.not_system`,
  `require_can_edit_users!`).

## Gotchas

- Do not edit system records by hand. Collections with `system` containing `'Entities'`, user
  groups with `system: true`, and roles with `system: true` are created and resynced by
  `Collection.maintain_system_groups` and `EntityAccess`; manual edits are overwritten or break
  the hidden system-user grant. Admin controllers hide them with `Collection.general`,
  `UserGroup.not_system`, and `AccessControl.user_managed`; when querying these tables, filter
  the same way.
- The tables grow with the data: every cohort, project group, and data source that has had
  per-entity access set owns one collection, two user groups, two roles, and two access
  controls. Counting `Role` or `Collection` rows without `not_system` gives inflated numbers.
- A new viewable entity type touches several places: a `has_many ... through:
  :group_viewable_entities, source_type:` on `Collection`, `Collection#entity_types`,
  `relevant_entity_types`, `collection_type_from`, the `viewable_types` map, `set_viewables`'
  type list, the admin collection form params in `Admin::CollectionsController`, a `viewable_by`
  scope on the new model that calls `collections_for_permission`, and, for anything client-scoped,
  `EnrollmentArbiter`.
- `can_x?` on `User` is true if any of the user's roles has the flag, regardless of collection.
  `Project.viewable_by(user, permission:)` first requires `user.can_x?`, then narrows by
  collection. A green `can_x?` does not mean access to a specific record.
- `permission:` on `viewable_by` scopes is ignored on the legacy branch; a user on legacy roles
  gets the legacy union. Specs for scope changes need a user on each `permission_context`.
- `UserGroupMember` does not include `UserPermissionCache`, and `UserGroup#add`/`remove` write
  the join row without saving the group. A membership change reaches `collections_for_permission`
  only after the 5-minute `Rails.cache` expiry, unless something else saves a cached model.
- Memoized permission state on a `User` is per request. Long-running exports and reports use the
  snapshot taken at the start; do not add `reload!` or cache busting inside a request.
- `EnrollmentArbiter#unscoped_clients` deliberately drops the `Client` default scope because the
  arbiter is often called from inside a client scope.

## Do not repeat

- Ad hoc visibility scopes (`visible_by`, `visible_to`, `accessible_by`) that re-derive access
  from roles or access groups. Write `viewable_by(user)` on the model, resolving ids through
  `user.collections_for_permission` and `GrdaWarehouse::GroupViewableEntity`, as
  `GrdaWarehouse::Cohort.viewable_by` (`app/models/grda_warehouse/cohort.rb:91`) does. Legacy
  example: `visible_by?` in `app/models/grda_warehouse/vispdat/base.rb:212`. Entry 2 in
  `conventions/do-not-repeat.md`.
- Querying `GrdaWarehouse::GroupViewableEntity` or `Collection` directly from feature code to
  decide access. That belongs inside a model's `viewable_by`/`editable_by` scope or a policy
  context (`app/models/grda_warehouse/auth_policies/user_acl_context.rb`); feature code calls
  the scope or `user.policy_for(record)`.
- Gating a record-level action on `current_user.can_x?` alone. Use `policy_for(record)`; see
  `authorization/warehouse-policies.md`.
- Creating `Collection`, `UserGroup`, `Role`, or `AccessControl` rows by hand to give a user
  access to one cohort, project group, or data source. Call `replace_access(users, scope:)` from
  `EntityAccess`, as `app/controllers/cohorts_controller.rb:186` does.
- New code that implements only the legacy branch of a `using_acls?` conditional. See
  `authorization/warehouse-legacy-roles.md`.

## Related

- `authorization/warehouse-legacy-roles.md`: the `role_based` path, `AccessGroup`, `UserRole`,
  and the `START_ACL`/`END_ACL` dual-path markers.
- `authorization/warehouse-policies.md`: `policy_for`, `UserAclContext`, controller
  `authorize_with`, PII policies.
- `roi/roi-authorizations-and-visibility.md`: how consent feeds the arbiter's ROI branch.
- `conventions/do-not-repeat.md`: repo-wide retired patterns, entries 1 and 2.
- `docs/features/warehouse/warehouse-permissions.md`: the human-facing description of this
  system, including the admin UI table.
