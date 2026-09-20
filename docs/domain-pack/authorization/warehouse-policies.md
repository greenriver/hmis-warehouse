---
title: Warehouse authorization policies and PiiProvider
summary: Policy classes under GrdaWarehouse::AuthPolicies, the UserAclContext/UserLegacyContext split, controller authorize_with blocks with the ensure_authorized after_action, and PiiProvider for name/SSN/DOB display decisions.
area: authorization
tags: [authorization, policy, BasePolicy, policy_for, authorize_with, ApplicationControllerV2, ensure_authorized, PiiProvider, AllowPiiPolicy, DenyPiiPolicy, context-loaders]
sources:
  - app/models/grda_warehouse/auth_policies/base_policy.rb
  - app/models/grda_warehouse/auth_policies/user_base_context.rb
  - app/models/grda_warehouse/auth_policies/user_acl_context.rb
  - app/models/grda_warehouse/auth_policies/user_legacy_context.rb
  - app/models/grda_warehouse/auth_policies/project_policy.rb
  - app/models/grda_warehouse/auth_policies/project_pii_policy.rb
  - app/models/grda_warehouse/auth_policies/destination_client_policy.rb
  - app/models/grda_warehouse/auth_policies/source_client_policy.rb
  - app/models/grda_warehouse/auth_policies/data_source_policy.rb
  - app/models/grda_warehouse/auth_policies/hud_report_policy.rb
  - app/models/grda_warehouse/auth_policies/cohort_pii_policy.rb
  - app/models/grda_warehouse/auth_policies/allow_pii_policy.rb
  - app/models/grda_warehouse/auth_policies/deny_pii_policy.rb
  - app/models/grda_warehouse/auth_policies/context_loaders/client_roi_loader.rb
  - app/models/grda_warehouse/auth_policies/context_loaders/restricted_client_loader.rb
  - app/models/grda_warehouse/pii_provider.rb
  - app/controllers/application_controller_v2.rb
  - app/controllers/concerns/controller_authorization_v2.rb
  - lib/util/authorization_not_performed_error.rb
  - lib/util/not_authorized_error.rb
  - app/models/user.rb
  - app/controllers/projects_controller.rb
related:
  - authorization/warehouse-access-controls.md
  - authorization/warehouse-legacy-roles.md
  - roi/roi-authorizations-and-visibility.md
  - warehouse/pii-and-restricted-clients.md
---

## Purpose

Warehouse policies are the current way to answer "may this user do X to this record" without
caring whether the user is on Access Controls or on legacy roles. A policy class under
`app/models/grda_warehouse/auth_policies/` holds the rules for one resource type (project,
source client, destination client, data source, HUD report instance). It reads permissions from
a context object built once per user per request: `GrdaWarehouse::AuthPolicies::UserAclContext`
or `GrdaWarehouse::AuthPolicies::UserLegacyContext`, both subclasses of `UserBaseContext`.

`GrdaWarehouse::PiiProvider` (`app/models/grda_warehouse/pii_provider.rb`) sits on top of the
PII policies. It decides, per field, whether a client's name, SSN, DOB, photo, or HIV status is
shown, masked, or replaced with `Redacted`. HMIS client restriction is folded in by
`PiiProvider.restrict`, which wraps any policy so every PII predicate returns false.

Controllers that subclass `ApplicationControllerV2` declare `authorize_with { ... }` blocks and
get an `after_action` that raises `AuthorizationNotPerformedError` if no block ran for the
action. This is the replacement for the legacy `before_action :require_can_*!` filters.

## Entry points

- `User#policy_for(resource, policy_class: nil)` (`app/models/user.rb`), memoized. Without
  `policy_class`, it calls `resource.policy_class` and raises `ArgumentError` if the model does
  not define it. With `policy_class`, the class must inherit from
  `GrdaWarehouse::AuthPolicies::BasePolicy`. Models defining `policy_class` today:
  `GrdaWarehouse::Hud::Project`, `GrdaWarehouse::Hud::Client` (chooses
  `DestinationClientPolicy` or `SourceClientPolicy` by `destination?(strict: true)`),
  `GrdaWarehouse::DataSource`, `HudReports::ReportInstance`.
- `User#policy_context`, memoized. Returns `UserAclContext` when `using_acls?`, else
  `UserLegacyContext`. Exposes `client_restricted?(client_id)`,
  `preload_project_dependencies(project_ids)`, `preload_client_dependencies(client_ids)`, and
  `client_roi_loader`.
- `User#reporting_policy_for_project(project_id:, mode: :browse, client_id: nil)` and
  `User#reporting_policy_for_client(client:, mode: :browse)` return a PII policy already wrapped
  by `PiiProvider.restrict`. `mode: :download` honors
  `GrdaWarehouse::Config.get(:include_pii_in_detail_downloads)`.
- `authorize_with(only:, except:) { ... }` class method from `ControllerAuthorizationV2`,
  available on any `ApplicationControllerV2` subclass. The block runs as a `before_action` in
  controller instance scope and calls `not_authorized!` when it returns false.
- `not_authorized!(message = nil)` on `ApplicationController` raises `NotAuthorizedError`
  (`lib/util/not_authorized_error.rb`), rescued into a redirect with a flash alert.
- `GrdaWarehouse::Hud::Client#pii_provider(user:)` for a single client (dashboard);
  `#project_pii_provider(project:, user:, mode:)` for project-scoped report rows.
- `GrdaWarehouse::PiiProvider.new(record, policy:)`, `.from_attributes(policy:, first_name:,
  ...)` for plucked rows, `.restrict(policy, restricted:)`, and the class-level
  `.viewable_name/.viewable_ssn/.viewable_dob/.viewable_hiv_status(value, policy:)` helpers.

## How it works

`BasePolicy#initialize(context:, resource:)` calls `validate_resource!(resource)`, which each
subclass overrides with `ensure_arg_type!(arg, Klass)`. Policies `include Memery` and memoize
expensive predicates. Most resource policies map role permission symbols to predicate names in
an array at the top of the class (`[:can_edit_projects, :can_edit?]`) and define each method as
`resource_permissions.include?(permission)`.

`resource_permissions` comes from the context. `UserAclContext` resolves permissions through
`Collection` membership joined to the user's `AccessControl` rows. `UserLegacyContext` does the
same through `AccessGroup` and returns the user's flat legacy role permissions when any group
matches. Both expose the same public methods (`project_role_permissions`,
`data_source_role_permissions`, `direct_client_role_permissions`,
`enrolled_project_ids_for_client`, `legacy_permissions`), so policies do not branch on user
type. `SourceClientPolicy` is the one policy that reads legacy-only data (window data sources).

Context loaders live under `auth_policies/context_loaders/`. `ClientRoiLoader` caches active
ROI matching the user's CoC codes per destination client id, with `preload(client_ids)`.
`RestrictedClientLoader` loads the full HMIS restricted id set once (direct, destination, and
sibling source ids) and answers `restricted?(id)` as a Set lookup.

`ControllerAuthorizationV2` sets `@authorization_performed = true` inside every
`authorize_with` block; `after_action :ensure_authorized` raises
`AuthorizationNotPerformedError` when the flag is unset. `ApplicationController.inherited`
includes `LegacyControllerAuthorization` only for subclasses that are not
`ApplicationControllerV2`, so the two systems never coexist in one controller.

PII policies are duck-typed: anything responding to `can_view?`, `can_view_name?`,
`can_view_full_ssn?`, `can_view_partial_ssn?`, `can_view_full_dob?`, `can_view_photo?`,
`can_view_hiv_status?`. `AllowPiiPolicy` and `DenyPiiPolicy` are singletons answering all true
or all false. `ProjectPiiPolicy` grants by project permissions; `SourceClientPolicy` and
`DestinationClientPolicy` (delegating to source clients) by client permissions.
`CohortPiiPolicy` allows everything except full SSN, which follows `user.can_view_full_ssn?`.
`PiiProvider::RestrictedPolicy` wraps any of these and forces every PII predicate false while
`can_view?` still delegates. `can_view_partial_ssn?` is true on every policy except
`RestrictedPolicy`: restriction means no SSN at all.

Adding a policy for a new resource type:

1. Create `app/models/grda_warehouse/auth_policies/<thing>_policy.rb`, class
   `GrdaWarehouse::AuthPolicies::<Thing>Policy < GrdaWarehouse::AuthPolicies::BasePolicy`.
2. Override `validate_resource!(arg)` with `ensure_arg_type!(arg, <Thing>)`.
3. List `[permission_symbol, predicate_name]` pairs and `define_method` each as
   `resource_permissions.include?(permission)`, as `ProjectPolicy` does.
4. Define `resource_permissions` by calling a context method (`project_role_permissions`,
   `data_source_role_permissions`, or `direct_client_role_permissions`) with the resource id.
5. Add `def policy_class = GrdaWarehouse::AuthPolicies::<Thing>Policy` to the model.
6. In the controller, subclass `ApplicationControllerV2` and declare
   `authorize_with { thing_policy.can_view? }` with a `helper_method def thing_policy` that
   calls `current_user.policy_for(@thing)`.
7. Spec both context types (a user with `using_acls?` true and one with it false).

## Key files

- `app/models/grda_warehouse/auth_policies/base_policy.rb`: constructor, `validate_resource!`,
  `ensure_arg_type!`, Memery.
- `app/models/grda_warehouse/auth_policies/user_base_context.rb`: loaders, `client_restricted?`.
- `app/models/grda_warehouse/auth_policies/user_acl_context.rb`: ACL permission resolution and
  preload methods.
- `app/models/grda_warehouse/auth_policies/user_legacy_context.rb`: legacy role resolution,
  `legacy_window_data_source_ids`, `legacy_window_access_requires_release?`.
- `app/models/grda_warehouse/auth_policies/project_policy.rb`: canonical resource policy.
- `app/models/grda_warehouse/auth_policies/source_client_policy.rb`: `can_view?` with ROI,
  `add_legacy_data_source_permissions`, `add_project_based_permissions`,
  `add_direct_client_permissions`.
- `app/models/grda_warehouse/auth_policies/destination_client_policy.rb`: delegates each
  predicate to `user.policy_for(source_client)` across source clients.
- `app/models/grda_warehouse/auth_policies/project_pii_policy.rb`: accepts a project id or
  project; used by `reporting_policy_for_project`.
- `app/models/grda_warehouse/auth_policies/data_source_policy.rb`,
  `hud_report_policy.rb`: small resource policies; `HudReportPolicy` still wraps `user.can_*?`.
- `app/models/grda_warehouse/auth_policies/allow_pii_policy.rb`, `deny_pii_policy.rb`,
  `cohort_pii_policy.rb`: PII-only policies without a resource.
- `app/models/grda_warehouse/auth_policies/context_loaders/client_roi_loader.rb`,
  `restricted_client_loader.rb`.
- `app/models/grda_warehouse/pii_provider.rb`: `RestrictedPolicy`, `restrict`, field accessors,
  SSN masking.
- `app/controllers/application_controller_v2.rb`,
  `app/controllers/concerns/controller_authorization_v2.rb`: `authorize_with`,
  `ensure_authorized`.
- `lib/util/authorization_not_performed_error.rb`, `lib/util/not_authorized_error.rb`.
- `app/models/user.rb`: `policy_for`, `policy_context`, `reporting_policy_for_project`,
  `reporting_policy_for_client`.
- `app/controllers/projects_controller.rb`: working `authorize_with` example.

## Gotchas

- A controller inheriting `ApplicationController` rather than `ApplicationControllerV2` gets
  `LegacyControllerAuthorization` and no `ensure_authorized` safety net. An action with no
  `before_action :require_can_*!` there is silently open.
- `authorize_with` blocks run in controller instance scope, before the action, so any instance
  variable they read must be set by an earlier `before_action`. `ProjectsController` orders
  `before_action :set_project` ahead of the `authorize_with` calls.
- `user.policy_for(record)` without `policy_class:` raises `ArgumentError` unless the model
  defines `policy_class`. Only `Project`, `Client`, `DataSource`, and `HudReports::ReportInstance`
  do today.
- `SourceClientPolicy` and `DestinationClientPolicy` raise if handed the wrong kind of client.
  `Client#policy_class` picks the right one; call `policy_for(client)` rather than constructing
  either directly.
- PII policies decide display, not query scope. Use `Model.viewable_by(user)` to limit which
  records load; use a PII policy only for what to show on each loaded row.
- Per-row policy checks in a list N+1 unless the context is warmed first:
  `current_user.policy_context.preload_project_dependencies(project_ids)` or
  `preload_client_dependencies(client_ids)`, on the paginated page not the full relation.
  `SourceClientPolicy#roi_authorized?` also hits `ClientRoiLoader`, which preloads per batch.
- Restricted client ids are loaded once per `User` instance and memoized for the request or job.
  A client restricted mid-way through a long export stays unrestricted in that export. Do not
  add cache busting for this.
- `PiiProvider#dob` and `#ssn` return `nil` for a blank value and `Redacted` (or a masked
  string) only when a value exists, so a redacted field cannot be told apart from an empty one
  by presence checks.
- `HudReportPolicy#can_view_checkpoints?` reads `user.can_*?` directly because report instances
  have no collection relationship. Do not copy that shape for resources that do.

## Do not repeat

- `before_action :require_can_*!` on a new controller. Replacement: subclass
  `ApplicationControllerV2` and use `authorize_with { policy.can_x? }`. Current example:
  `app/controllers/projects_controller.rb:13`. Repo-wide entry: `conventions/do-not-repeat.md`,
  entry 1.
- Direct `client.FirstName`, `client.name`, `client.SSN`, or `client.DOB` in a view, export, or
  report row that can include an HMIS-restricted client. Replacement:
  `client.pii_provider(user: current_user).full_name` (dashboard),
  `client.project_pii_provider(project:, user:, mode:)` (report row with a live client), or
  `PiiProvider.viewable_name(value, policy: current_user.reporting_policy_for_project(...))`
  (snapshot row with no client record). Current example:
  `app/models/grda_warehouse/hud/client.rb:1405`.
- Reading `user.can_view_clients?` or another flat `can_*?` flag to gate a record. Replacement:
  `user.policy_for(record).can_view?`, which scopes the permission to the record through the
  user's collections or access groups.
- Constructing a new `UserAclContext` or `UserLegacyContext` per check. Replacement:
  `user.policy_context`, memoized for the request.

## Related

- `authorization/warehouse-access-controls.md`: how `UserAclContext` permissions are granted.
- `authorization/warehouse-legacy-roles.md`: the `UserLegacyContext` side and `using_acls?`.
- `roi/roi-authorizations-and-visibility.md`: what `ClientRoiLoader` reads.
- `warehouse/pii-and-restricted-clients.md`: restriction sources, search exclusion, exports.
- `conventions/do-not-repeat.md`: entry 1 (`require_can_*!`).
- Human-facing source: `docs/features/warehouse/warehouse-auth-policies.md` and the
  Authorization section of `docs/code_patterns_and_conventions.md`.
