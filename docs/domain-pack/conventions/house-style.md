---
title: House style for Ruby, Rails views, queries, and jobs
summary: Repo-wide coding conventions an agent must follow when adding or editing warehouse Ruby, HAML, JavaScript, queries, or background jobs. Points at the rubocop cops that enforce some of them.
area: conventions
tags: [conventions, style, views, haml, stimulus, esbuild, csp-nonce, markdown, html_safe, strong-params, concerns, callbacks, service-objects, arel, update_all, rubocop, jobs, pii_attr, RemoteCredential, AppConfigProperty]
sources:
  - docs/code_patterns_and_conventions.md
  - docs/active-record-arel-and-queries.md
  - lib/rubocop/cop/queries/unsafe_bulk_update_sql.rb
  - lib/rubocop/cop/queries/date_interpolation_in_sql.rb
  - lib/rubocop/cop/migrations/disable_ddl_transaction.rb
  - lib/util/hud_helper.rb
  - app/renderers/safe_user_markdown.rb
  - app/renderers/translated_html.rb
related:
  - conventions/do-not-repeat.md
---

## Purpose

The conventions that apply everywhere in this repository, condensed for an agent about to write
or review code. The human-facing source is `docs/code_patterns_and_conventions.md`. Deprecated
patterns that still exist in the codebase are catalogued separately in
`conventions/do-not-repeat.md`. Authorization, GraphQL, and driver architecture conventions live
in their own area docs (`authorization/`, `hmis/graphql-layer.md`, `warehouse/driver-architecture.md`).

## Entry points

- `docs/code_patterns_and_conventions.md` is the prescriptive human document. Read it when a
  rule here needs its rationale.
- `docs/active-record-arel-and-queries.md` explains the query preference ladder and the hazards
  behind it.
- Three custom rubocop cops are required from `.rubocop.yml`:
  `lib/rubocop/cop/queries/unsafe_bulk_update_sql.rb`,
  `lib/rubocop/cop/queries/date_interpolation_in_sql.rb`,
  `lib/rubocop/cop/migrations/disable_ddl_transaction.rb`. Run `bundle exec rubocop` on changed
  files, including specs, once at the end of a change.

## How it works

### Views and JavaScript

- Index pages render collections with `render_paginated_list(scope:, item_name:, list_partial:)`.
  Example: `app/views/secure_files/index.haml`.
- Per-row project policy checks on a paginated page N+1 unless dependencies are preloaded against
  the paginated page, not the full relation. Controller-paginated:
  `current_user.policy_context.preload_project_dependencies(ids)` right after `pagy`.
  View-paginated (`render_paginated_list`): preload inside the partial that receives `list`.
  Client restriction needs no preload; it is loaded once per request.
- View helpers go on the controllers that use them, not `ApplicationHelper`, unless truly global.
- New JavaScript goes in `app/javascript` and is built by esbuild. Most of it is a Stimulus
  controller: file `snake_case_controller.js`, default-exported `PascalCase` class, `kebab-case`
  identifier. Global controllers register through `app/javascript/controllers/index.js`. A
  controller for one heavy page gets its own entry file and is pulled in with
  `content_for :page_js` (example: `app/views/data_quality_reports/version_three.haml`).
- Inline scripts must carry the CSP nonce: HAML `%script{ nonce: content_security_policy_nonce }`,
  ERB `javascript_tag nonce: true do ... end`. HAML's `:javascript` filter cannot take a nonce.
  Inline `style=` is not nonce-protected yet; avoid inline styles and use Bootstrap classes.

### Rich text and HTML safety

- Markdown renders through `SafeUserMarkdown.render` (`app/renderers/safe_user_markdown.rb`) or
  `TranslatedHtml` (`app/renderers/translated_html.rb`) when `{{Key}}` translation substitution is
  needed. Both set `escape_html: true, safe_links_only: true` and call `.html_safe` only on the
  rendered output.
- HTML fragments built from dynamic pieces use `safe_join` with `content_tag` parts
  (example: `app/models/cohort_columns/open_enrollments.rb`), never string interpolation followed
  by `.html_safe`.
- Free-form HTML that must keep some tags goes through `Rails::Html::SafeListSanitizer` or
  `sanitize(text, tags:, attributes:)` (example: `app/models/message.rb`).

### Controllers

- Strong parameters, usually a private `<noun>_params` method. Business logic lives in a model
  method or a service object, not the action.
- Exceptions bubble up. A `rescue` names a specific exception class and forwards to Sentry if it
  would otherwise hide the error. Never bare `rescue` or `rescue StandardError`.

### PII and credentials

- A model that may store personally identifiable information declares each field with
  `pii_attr` from `HasPiiAttributes`, with `as:` and `level:` for sensitivity
  (example: `app/models/reporting/housed.rb`). Health classes use a parallel PHI pattern.
- Credentials and related configuration live in `GrdaWarehouse::RemoteCredential`, an STI model
  with one subclass per kind (`app/models/grda_warehouse/remote_credentials/`).

### Models

- Concerns are named for what they do (`Filterable`, `HasPiiAttributes`), never with a
  `_concern`, `_mixin`, or `_behavior` suffix. Shape: `extend ActiveSupport::Concern`, an
  `included do` block, and a nested `module ClassMethods`. Example: `app/models/concerns/filterable.rb`.
- Callbacks only for persistence side effects such as cache invalidation
  (`after_save :invalidate_user_permission_cache` in `app/models/access_control.rb`), derived
  system records, or notifications. Domain logic is an explicit method or service object.
- HUD-coded fields (race, project type, destination, and every other HUD list) never use Rails
  `enum`. Use `HudHelper.util(hud_version).races` and friends (`lib/util/hud_helper.rb`), which
  resolves to `HudUtility2024`, `HudUtility2026`, or `HudUtilityLegacy`.
- Single Table Inheritance is a deliberate choice, not a default. Avoid it for year-versioned
  classes. If old typed rows remain, keep a stub subclass; Rails raises on an orphaned `type`.

### Service objects

- Prefer a service object over more logic in a model or controller. Shape:
  `def self.call(...) = new(...).call` plus an instance `#call`
  (example: `app/services/idp/admin_user_creator.rb`). Both `app/models/` and `app/services/`
  are in use; location is not enforced.

### Configuration

- Installation settings live in the database: `GrdaWarehouse::Config` for known settings and
  `AppConfigProperty` (`app/models/app_config_property.rb`) as the generic key-value home. Do not
  add ENV-driven configuration.

### Database queries

- Preference ladder: standard ActiveRecord and scopes, then `merge` to apply another model's
  scope across a join, then Arel for conditions the hash form cannot express or that touch
  case-sensitive HUD column and table names, then raw SQL only with bind parameters.
- `merge` of two scopes on the same model replaces a same-column predicate instead of ANDing
  it; chain `where` for that.
- Date and time comparisons use ranges: `where(created_at: ..time)` or `where(created_at: ...time)`.
- Never pass a raw SQL string to `update_all`, `delete_all`, or `update_counters`; on joined
  relations Rails 8.1 aliases the table and bare columns become ambiguous. Enforced by
  `Queries/UnsafeBulkUpdateSql`.
- Never interpolate a Date or Time into SQL; `Date#to_s` renders a human format in this app.
  Use bind parameters, or `.iso8601` / `.to_fs(:db)`. Enforced by `Queries/DateInterpolationInSql`.
- Migrations never call `disable_ddl_transaction!`. Enforced by `Migrations/DisableDdlTransaction`.
- Prefer associations over manual joins. HUD models relate through `data_source_id` plus a HUD
  ID, so verify the association exists before joining by hand.
- Reuse scope names already in use: `.active`, `.ordered`, `.for_user(user)`, `.newest_first`.

### Background jobs and reports

- Jobs inherit from `BaseJob` (`app/jobs/base_job.rb`). Exceptions bubble to Sentry; nothing
  swallows them. No exceptions for control flow; use normal flow or `catch`/`throw`.
- Official HUD reports use `HudReports::ReportInstance` and render the shared `hud_reports/index`
  and `hud_reports/show` partials. Other background reports use `SimpleReports::ReportInstance`
  and the `common/background_report/history_filter` and `history_table` partials.

### Testing

- Build test objects with factories, not model constructors.
- Run only the specs tied to the change, on the `spec` compose service. The full suite runs in CI.

## Key files

- `docs/code_patterns_and_conventions.md`, `docs/active-record-arel-and-queries.md`: source rules.
- `lib/rubocop/cop/queries/unsafe_bulk_update_sql.rb`,
  `lib/rubocop/cop/queries/date_interpolation_in_sql.rb`,
  `lib/rubocop/cop/migrations/disable_ddl_transaction.rb`: enforced rules with rationale in
  each file's header comment.
- `app/renderers/safe_user_markdown.rb`, `app/renderers/translated_html.rb`: safe markdown.
- `lib/util/hud_helper.rb`: HUD code list dispatcher.
- `app/models/concerns/filterable.rb`: canonical concern shape.
- `app/services/idp/admin_user_creator.rb`: canonical service object shape.
- `app/views/secure_files/index.haml`: `render_paginated_list` example.

## Gotchas

- The esbuild bundle waits for jQuery and select2 loaded by Sprockets before starting Stimulus.
  Sprockets is deprecated for new code but is a live runtime dependency.
- `safe_join` is the idiomatic helper yet rare in this codebase; older views build tooltips with
  `content_tag` composition or interpolation. Follow the rule, not the neighbors.
- `Date#to_s` is overridden to a human format application-wide, which is why date interpolation
  into SQL or JSONB keys fails silently.
- Two custom cops fire only on the shapes they recognize; a raw SQL string built elsewhere and
  passed as a variable is not caught. The rule still applies.

## Do not repeat

See `conventions/do-not-repeat.md` for the deny-list, with replacements and examples.

## Related

- `conventions/do-not-repeat.md`
- `authorization/warehouse-policies.md` (controller `authorize_with`, record policies)
- `authorization/hmis-graphql-authorization.md`
- `hmis/graphql-layer.md`
- `warehouse/driver-architecture.md`
- `hud-reporting/hud-utility-versions.md`
