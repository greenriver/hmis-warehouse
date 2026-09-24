---
title: Warehouse legacy role-based permissions
summary: How the pre-ACL warehouse permission system works (Role can_* columns, UserRole, require_can_*! before_actions, START_ACL/END_ACL dual-path code) so an agent can recognize it, keep it working, and not extend it.
area: authorization
tags: [authorization, legacy, role, can_, require_can, UserRole, START_ACL, END_ACL, using_acls]
sources:
  - app/models/role.rb
  - app/models/user_role.rb
  - app/models/user.rb
  - app/models/concerns/user_permissions.rb
  - app/models/concerns/user_permission_cache.rb
  - app/controllers/application_controller.rb
  - app/controllers/concerns/legacy_controller_authorization.rb
  - app/models/access_group.rb
  - app/models/access_group_member.rb
  - app/models/concerns/access_groups.rb
  - app/models/concerns/user_concern.rb
  - lib/util/not_authorized_error.rb
related:
  - authorization/warehouse-access-controls.md
  - authorization/warehouse-policies.md
  - conventions/do-not-repeat.md
---

## Purpose

The warehouse has two permission systems that share the `Role` model. The legacy one assigns a
`Role` straight to a `User` through `UserRole`, and scopes the user to entities through
`AccessGroup`. The current one ("ACLs") grants a `Role` to a `UserGroup` over a `Collection`
through `AccessControl`; see `authorization/warehouse-access-controls.md`.

`User#using_acls?` (`app/models/concerns/user_concern.rb`) picks the path per user: it is true
when the `users.permission_context` column equals `'acls'`; `nil` or `'role_based'` means
legacy. `User.using_acls` and `User.using_role_based` scopes filter on the same column.

This doc exists so an agent can recognize the legacy path when reading or touching it, keep it
working (both paths run in production), and avoid extending it. The legacy path is being removed;
`UserRole`, `AccessGroup`, `AccessGroupMember`, and the `AccessGroups` concern are marked
`START_ACL remove ...` in their source.

## Entry points

- `Role.permissions_with_descriptions` (`app/models/role.rb`): the hash that defines every
  permission with description, category, sub-category, and `administrative:` flag.
  `Role.permissions` is its keys. Both systems read it.
- `User#can_<permission>` and `User#can_<permission>?` (`app/models/user.rb`): generated for
  every `Role.permissions` key. They read `load_effective_permissions`, which unions the flags
  from `roles` (ACL path) or `legacy_roles` (legacy path) based on `using_acls?`.
- `User.can_<permission>` scope: users holding the flag through either path.
- Composite predicates in `UserPermissions` (`app/models/concerns/user_permissions.rb`), for
  example `can_view_or_search_clients`, listed in `User.additional_permissions`. Some branch on
  `using_acls?` internally.
- `require_can_<permission>!` (`app/controllers/concerns/legacy_controller_authorization.rb`):
  generated for every `Role.permissions` key and every `User.additional_permissions` entry.
  Calls `not_authorized!` unless `current_user` has the flag. Used as `before_action` in 212
  controller files.
- `ApplicationController#not_authorized!` raises `NotAuthorizedError`
  (`lib/util/not_authorized_error.rb`); `rescue_from` redirects to the user's root path with the
  message as a flash alert.
- `User#policy_context` returns `GrdaWarehouse::AuthPolicies::UserLegacyContext` for a legacy
  user and `UserAclContext` for an ACL user, so `user.policy_for(record)` works on both paths.
  See `authorization/warehouse-policies.md`.

## How it works

Permissions are boolean columns on the `roles` table, one per key in
`Role.permissions_with_descriptions` (126 keys as of 2026-09; `grep -c "can_"
app/models/role.rb` reports 164 because it also counts 25 retired health columns listed in
`ignored_columns` and mentions in descriptions). Adding a permission means adding a key to the
hash and running `Role.ensure_permissions_exist` in a migration, which `add_column`s any
missing key.

`UserRole` (`app/models/user_role.rb`) joins `users` to `roles` with no entity scope. A legacy
user's effective permissions are the union of flags over all their `legacy_roles`; the same flag
set applies to every entity they can see.

Entity scope in the legacy world comes from `AccessGroup` (`app/models/access_group.rb`) and
`AccessGroupMember`. An `AccessGroup` holds polymorphic `GrdaWarehouse::GroupViewableEntity`
rows for data sources, organizations, projects, project access groups, reports, project groups,
and cohorts. Each user also has a personal group (`AccessGroup.for_user`, `User#access_group`).
`User#ids_for_relations` unions the user's groups plus the personal group on the legacy path,
or `collections` on the ACL path. The `AccessGroups` concern (`app/models/concerns/access_groups.rb`)
lets an entity list and update the groups that contain it.

`UserPermissionCache` (`app/models/concerns/user_permission_cache.rb`) defines
`invalidate_user_permission_cache`, which calls `User.clear_cached_permissions` to delete every
`Rails.cache` key with the `user_permissions` prefix. `Role`, `AccessControl`, `Collection`, and
`UserGroup` run it `after_save`. `UserRole`, `AccessGroup`, and `AccessGroupMember` do not; the
cached entries expire after `User::EXPIRY_MINUTES` (5) and are bypassed in the test environment.

Dual-path code is fenced with `# START_ACL` and `# END_ACL` comments (sometimes
`TODO: START_ACL remove after ACL migration is complete`). 40 files under `app` and `drivers`
carry the marker. Code inside a fence is the legacy branch or the switch between branches and
is scheduled for deletion.

## Key files

- `app/models/role.rb`: `Role`, `permissions_with_descriptions`, `ensure_permissions_exist`,
  `after_save :invalidate_user_permission_cache`.
- `app/models/user_role.rb`: legacy `users`-to-`roles` join, paper-trailed.
- `app/models/user.rb`: generated `can_*` methods and scopes, `load_effective_permissions`,
  `ids_for_relations`, `policy_context`, `clear_cached_permissions`.
- `app/models/concerns/user_permissions.rb`: composite predicates and `additional_permissions`.
- `app/models/concerns/user_permission_cache.rb`: `invalidate_user_permission_cache`.
- `app/controllers/application_controller.rb`: `not_authorized!`, `rescue_from
  NotAuthorizedError`, and `self.inherited`, which includes `LegacyControllerAuthorization` into
  every subclass that is not an `ApplicationControllerV2`.
- `app/controllers/concerns/legacy_controller_authorization.rb`: generated `require_can_*!`
  and the hand-written `require_can_see_this_client_demographics!`.
- `app/models/access_group.rb`: legacy entity scope, system groups, `set_viewables`.
- `app/models/access_group_member.rb`: `users`-to-`access_groups` join.
- `app/models/concerns/access_groups.rb`: `access_group_ids`, `update_access`,
  `remove_from_group_viewable_entities!` for entities that appear in groups.

## Gotchas

- Legacy and ACL users coexist in one database. `User.anyone_using_acls?` and
  `User.all_using_acls?` exist because neither state can be assumed. Any change to code that
  branches on `using_acls?` (arbiters, `ids_for_relations`, composite predicates in
  `UserPermissions`, context classes) needs specs for a user with `permission_context: 'acls'`
  and one with `'role_based'`.
- `user.can_x?` answers "does any of this user's roles have the flag"; it ignores entity scope
  on both paths. It is not a substitute for `policy_for(record).can_x?` or
  `Model.viewable_by(user)`.
- A legacy user cannot hold different permission levels on different entities. Features that
  need per-entity grants only work correctly for ACL users.
- `Role` is shared: a `Role` attached to an `AccessControl` is "new", the same class attached
  through `user_roles` is "legacy". Editing a role's flags affects both kinds of users.
- Saving `UserRole`, `AccessGroup`, or `AccessGroupMember` does not clear the permission cache;
  stale legacy permissions can persist for up to 5 minutes outside the test environment.
- `LegacyControllerAuthorization` is added by `ApplicationController.inherited`, so a controller
  that switches to `ApplicationControllerV2` loses `require_can_*!` and must use
  `authorize_with`.
- `Role.permissions_with_descriptions` is the single source for both the legacy and ACL admin
  UIs; renaming a key without a migration breaks `Role.ensure_permissions_exist` and the
  generated `User` methods.

## Do not repeat

- `before_action :require_can_<permission>!` in a controller. Replace with a controller that
  subclasses `ApplicationControllerV2` and declares `authorize_with { ... }` using
  `current_user.policy_for(record)`. See `conventions/do-not-repeat.md` entry 1 and
  `authorization/warehouse-policies.md`.
- `current_user.can_x?` as the only check on a record-level action or query. Replace with
  `policy_for(record).can_x?` for a record and `Model.viewable_by(user)` for a scope. See
  `conventions/do-not-repeat.md` entry 2 for the scope form.
- New `AccessGroup`, `AccessGroupMember`, or `UserRole` usage, including including the
  `AccessGroups` concern in a new model. Entity scope belongs in a `Collection` and a grant in an
  `AccessControl`.
- New code inside a `START_ACL`/`END_ACL` fence that implements only the legacy branch. When a
  fenced block must change, change the ACL branch and keep the legacy branch as it is; add a
  spec for each branch.
- A new key in `Role.permissions_with_descriptions` is still the right way to add a permission,
  but the code that consumes it must go through a policy, not a `can_*` flag.

## Related

- `authorization/warehouse-access-controls.md`: the current `AccessControl`, `Collection`,
  `UserGroup` model that replaces `UserRole` and `AccessGroup`.
- `authorization/warehouse-policies.md`: `policy_for`, `UserLegacyContext` versus
  `UserAclContext`, `ApplicationControllerV2` and `authorize_with`.
- `conventions/do-not-repeat.md`: repo-wide deny-list; entries 1 and 2 cover `require_can_*!`
  and ad hoc visibility scopes.
- `docs/features/warehouse/warehouse-permissions.md`: human-facing description of both systems.
