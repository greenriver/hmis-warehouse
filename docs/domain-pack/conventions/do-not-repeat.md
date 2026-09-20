---
title: Patterns not to repeat
summary: Deny-list of deprecated or unsafe patterns that still exist in the codebase. Each entry names the replacement and an example. Check this before copying an existing pattern.
area: conventions
tags: [deny-list, deprecated, legacy, anti-pattern, require_can, visible_by, RailsDrivers, sprockets, coffeescript, html_safe, enum, update_all, rescue, BaseMutation, permissions-kwarg, current_permission?, is_a?, ENV]
sources:
  - CLAUDE.md
  - docs/code_patterns_and_conventions.md
  - docs/adr/0006-policy-based-graphql-access-fields.md
  - lib/rubocop/cop/queries/unsafe_bulk_update_sql.rb
  - lib/rubocop/cop/queries/date_interpolation_in_sql.rb
  - lib/util/hud_helper.rb
  - drivers/hmis/app/graphql/mutations/base_mutation.rb
  - drivers/hmis/app/graphql/mutations/clean_base_mutation.rb
  - drivers/hmis/app/graphql/types/base_access.rb
  - drivers/hmis/app/graphql/types/base_field.rb
  - drivers/hmis/app/graphql/concerns/graphql_permission_checker.rb
related:
  - conventions/house-style.md
---

## Purpose

A list of patterns an agent will find in this codebase and must not copy. Each entry gives the
pattern, why it is retired, what to write instead, and where to see each form. Counts are from
2026-09-19 and show how common the legacy form still is; a common legacy form is not a license
to add one more. Do not refactor legacy occurrences on sight; only avoid new ones.

## Entry points

- `conventions/house-style.md` states the positive conventions these entries violate.
- `docs/code_patterns_and_conventions.md` and `docs/adr/0006-policy-based-graphql-access-fields.md`
  record the decisions behind the authorization and GraphQL entries.
- Two rubocop cops enforce entries 8 and 9; the rest rely on review.

## How it works

### 1. `before_action :require_can_*!`
- Pattern: controller gated by a generated `require_can_<permission>!` method. Over 200 controller files under `app` and `drivers` still do this.
- Why: too coarse; checks a role flag with no entity scope, and does not work for users on Access Controls.
- Instead: subclass `ApplicationControllerV2` and declare `authorize_with { policy.can_x? }`; for a record, `user.policy_for(record)` then `not_authorized!`.
- Example: legacy in most of `app/controllers/`; replacement pattern in `docs/code_patterns_and_conventions.md` "Authorization on a controller action".

### 2. `visible_by` and other visibility scope variants
- Pattern: a per-model `visible_by(user)` scope or class method (`app/models/grda_warehouse/client_file.rb`, `app/models/grda_warehouse/client_notes/base.rb`).
- Why: predates policy-based authorization; each copy re-derives access rules.
- Instead: `Model.viewable_by(user)`, backed by the access-control machinery.

### 3. Gating behavior on driver loading
- Pattern: `RailsDrivers.loaded.include?(...)` or any check that a driver "is loaded".
- Why: all drivers always load; the `RailsDrivers` shim was removed repo-wide, so any reference to the constant raises `NameError`.
- Instead: call the driver's code directly.

### 4. New JavaScript under `app/assets/javascripts`
- Pattern: Sprockets assets or CoffeeScript (73 `.coffee` files remain).
- Why: the asset pipeline is deprecated for new code; esbuild builds `app/javascript`.
- Instead: a Stimulus controller in `app/javascript/controllers/`, registered globally or via a page entry file. See `conventions/house-style.md`.

### 5. Inline script without a CSP nonce
- Pattern: HAML `:javascript` filter, or a `<script>` tag without `nonce`. None remain in `app/views`; keep it that way.
- Why: the browser refuses to run it under the nonce-based `script-src` policy.
- Instead: `%script{ nonce: content_security_policy_nonce }` or `javascript_tag nonce: true`.

### 6. `"...#{value}...".html_safe` and hand-rolled Redcarpet
- Pattern: interpolating text into a string and marking it safe, for example the tooltip titles in `app/views/clients/_enrollment_table.haml`; or `Redcarpet::Markdown.new(Redcarpet::Render::HTML, ...)` without `escape_html`.
- Why: stored XSS whenever the interpolated value is user or client data.
- Instead: `safe_join` of `content_tag` parts; `SafeUserMarkdown.render` or `TranslatedHtml` for markdown; `Rails::Html::SafeListSanitizer` for free-form HTML.

### 7. Rails `enum` or hard-coded integers for HUD-coded fields
- Pattern: `enum` on a HUD list column, or a literal HUD code compared inline.
- Why: HUD lists change by fiscal year and contain multi-valued and "unknown" sentinel codes.
- Instead: `HudHelper.util(hud_version)` (`lib/util/hud_helper.rb`).

### 8. Raw SQL string in `update_all`, `delete_all`, `update_counters`
- Pattern: `scope.update_all("col = ...")`.
- Why: on joined relations Rails 8.1 aliases the target table; bare columns raise `PG::AmbiguousColumn`.
- Instead: hash form or Arel. Enforced by `Queries/UnsafeBulkUpdateSql` (`lib/rubocop/cop/queries/unsafe_bulk_update_sql.rb`).

### 9. Date or Time interpolated into SQL
- Pattern: `where("x < '#{date}'")` or a date inside a JSONB key string.
- Why: `Date#to_s` is a human format here, so the SQL silently matches nothing.
- Instead: bind parameters, ranges, or `.iso8601` / `.to_fs(:db)`. Enforced by `Queries/DateInterpolationInSql`.

### 10. Bare `rescue` or `rescue StandardError`
- Pattern: broad rescue that swallows or logs and continues.
- Why: hides failures from Sentry; jobs and imports then fail silently.
- Instead: rescue a specific class only when there is a real recovery; otherwise let it raise.

### 11. Type dispatch with `is_a?`
- Pattern: `if obj.is_a?(SomeClass)` to choose behavior (71 model files use `is_a?`, many legitimately for value checks).
- Why: project convention in `CLAUDE.md`: ask what an object can do, not what it is.
- Instead: a capability predicate such as `service.supports_backfill?` defined on each participant.

### 12. Editing a shipped fiscal-year HUD report generator
- Pattern: changing `FyXXXX::Generator` or its questions for a new HUD spec year.
- Why: old years must stay reproducible for already-run reports.
- Instead: a new sibling `FyYYYY` namespace registered in the driver's feature initializer. Detail in `hud-reporting/report-framework.md`.

### 13. GraphQL `BaseMutation`
- Pattern: `class Foo < BaseMutation` (32 mutations; 47 use the replacement).
- Why: legacy Relay-style scaffolding (`drivers/hmis/app/graphql/mutations/base_mutation.rb`).
- Instead: `CleanBaseMutation` (`drivers/hmis/app/graphql/mutations/clean_base_mutation.rb`), for example `drivers/hmis/app/graphql/mutations/delete_unit_group.rb`. `delete_project.rb` is a legacy example.

### 14. Raw-permission GraphQL access helpers
- Pattern: `Types::BaseAccess.can :permission` (marked legacy in `drivers/hmis/app/graphql/types/base_access.rb`), the `permissions:` kwarg on `Types::BaseField`, and `current_permission?` (16 files), all routed through `GraphqlPermissionChecker`. `composite_perm` and `root_can`, named in ADR 0006, no longer exist.
- Why: they resolve raw permission flags, bypass policy requirement resolution, and can leak permissions across HMIS data sources.
- Instead: `bool_field` with a policy predicate, `authorize_with:` on fields, `access_denied!` in mutations (ADR 0006). See `authorization/hmis-graphql-authorization.md`.

### 15. ENV variables for installation settings
- Pattern: reading `ENV[...]` for a per-installation toggle.
- Why: unmanageable across installations; the database is the configured home.
- Instead: `GrdaWarehouse::Config` for a known setting, `AppConfigProperty` otherwise.

### 16. Ad hoc credential storage
- Pattern: API keys or hosts in a model column, config file, or ENV.
- Why: one place to rotate and audit.
- Instead: a `GrdaWarehouse::RemoteCredential` STI subclass (`app/models/grda_warehouse/remote_credentials/`).

## Key files

- `drivers/hmis/app/graphql/types/base_access.rb`: `can` (legacy) beside `bool_field` (current).
- `drivers/hmis/app/graphql/types/base_field.rb`: the `permissions:` kwarg to avoid.
- `drivers/hmis/app/graphql/concerns/graphql_permission_checker.rb`: what the legacy helpers call.
- `drivers/hmis/app/graphql/mutations/base_mutation.rb`, `clean_base_mutation.rb`: legacy and current mutation bases.
- `lib/rubocop/cop/queries/*.rb`: the two enforced entries.

## Gotchas

- Legacy forms outnumber the replacement in several entries (1, 13). Follow the replacement even
  when every neighboring file does the old thing.
- ADR 0006 allows legacy GraphQL helpers to coexist during migration; that permits leaving them,
  not adding them.
- Entry 11 is a design convention, not a lint; `is_a?` used to validate an argument type is fine.

## Do not repeat

This whole document.

## Related

- `conventions/house-style.md`
- `authorization/warehouse-legacy-roles.md` (entry 1 background)
- `authorization/warehouse-access-controls.md` (entry 2)
- `authorization/hmis-graphql-authorization.md` (entries 13, 14)
- `hud-reporting/report-framework.md` (entry 12)
- `hud-reporting/hud-utility-versions.md` (entry 7)
