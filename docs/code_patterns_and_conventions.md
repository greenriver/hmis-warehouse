# Application Code Patterns and Conventions Guide

This document outlines the preferred patterns and conventions for code contributors. The goal is to improve code consistency and discoverability across the project.

This is a living document, please add or update patterns as appropriate. When adding new patterns, please include relevant details / rationale to help others understand how and why to use this pattern.

Note that this document may include code that is only in use in a handful of locations.  We recognize change can take time.  Sometimes patterns are added here after only being added to one of many locations in the codebase. Please follow these conventions and patterns if there is a relevent pattern listed.

## Table of Contents

- [Server-side views](#server-side-views)
- [Rich Text and Markdown Rendering Safety](#rich-text-and-markdown-rendering-safety)
- [Controllers](#controllers)
- [Authorization](#authorization)
- [Models](#models)
- [Service Objects](#service-objects)
- [Installation-specific configuration](#installation-specific-configuration)
- [Database Queries](#database-queries)
- [Background Async Jobs](#background-async-jobs)
- [Driver Architecture](#driver-architecture)
- [GraphQL](#graphql)
- [Testing](#testing)
- [Background Reports](#background-reports)

## Server-side views

### Rendering a resource list

For a collection of resources on an index page, prefer using a helper to render a table. This encapsulates the specifics of our pagination (pagy gem), reduces boilerplate, and improves UI consistency

```ruby
  render_paginated_list(scope: @data_sets, item_name: 'data set', list_partial: 'list')
```

### View Helper methods

Avoid defining global view helpers on ApplicationHelper unless the helper is truly global in scope. Instead constrain the helper to just the controllers where it is used.

### View Asset Management

When creating new JavaScript assets, use esbuild in `app/javascript`. Don't add new files to `app/assets/javascripts`.

Most JavaScript should be implemented as Stimulus controllers which live under `app/javascript/controllers/`.  Controllers are named `snake_case_controller.js` with a default-exported `PascalCase` class, registered under a `kebab-case` identifier. There are two registration paths, choose based on use scope:

- A controller meant for use on any page is registered globally through the auto-generated `app/javascript/controllers/index.js`.
- A controller only relevant to one heavy/specialized page instead gets its own small esbuild entry file (`app/javascript/<name>.js`) that registers onto the already-running Stimulus application (e.g. `window.Stimulus.register(...)` guarded by `if (window.Stimulus)`) and is pulled onto just that view via `content_for :page_js`.

Don't register a single-page controller globally — it bloats the shared bundle every page pays for. Don't hand-roll a page-specific entry point for something that should be usable anywhere.

CoffeeScript and the legacy asset pipeline are deprecated — do not write new CoffeeScript or place new JavaScript files in `app/assets/javascripts/*`.  The Sprockets asset pipeline still runs, and for the transition period the esbuild bundle waits for jQuery/select2 from it before initializing Stimulus; it's a real runtime dependency today, not dead code to ignore.

### Content Security Policy nonces for inline scripts

`config/initializers/content_security_policy.rb` configures `content_security_policy_nonce_generator` (a fresh random value per request) and `content_security_policy_nonce_directives = ['script-src']`. A CSP nonce is a per-request random token that must match between the `Content-Security-Policy` response header and a `<script>` tag's `nonce` attribute for the browser to execute that script. Because the nonce changes every request and isn't in the page an attacker's injected markup would have to guess, this is what lets `script-src` actually block XSS: only scripts the app itself rendered (with the correct nonce) run, so injected `<script>` tags are inert even where `unsafe-inline` is still listed as a legacy fallback.

Any inline `<script>` a view renders must carry this nonce or the browser will refuse to execute it:

```haml
%script{ nonce: content_security_policy_nonce }
  :plain
    var foo = #{bar};
```

Don't use HAML's `:javascript` filter for new inline scripts — it emits a bare `<script>` tag with no way to add the `nonce` attribute. In ERB, use `javascript_tag nonce: true do ... end` instead.

Note that `style_src` still includes `:unsafe_inline` unconditionally — inline `style=` attributes and `<style>` blocks are not yet nonce-protected. Prefer avoiding inline styles regardless (see Styles guidance in project instructions).

## Rich Text and Markdown Rendering Safety

### The safe pattern

Render markdown through `SafeUserMarkdown.render`, or `TranslatedHtml` when the content also needs `{{Key}}` translation substitution. Both wrap Redcarpet with `escape_html: true, safe_links_only: true` and only call `.html_safe` on the rendered *output* — never on raw interpolated text.  Avoid hand-rolled `Redcarpet::Markdown.new(Redcarpet::Render::HTML, ...)`.

### Building an HTML fragment (e.g. a tooltip) from dynamic pieces

Use `safe_join` — Rails' helper for concatenating already-escaped fragments — rather than string interpolation:

```ruby
safe_join([content_tag(:b, 'Prior Living Situation:'), ' ', living_situation])
```

### Free-form HTML content (not markdown)

For content that needs to allow some real HTML rather than markdown (e.g. email message bodies), use `Rails::Html::SafeListSanitizer` / `sanitize(text, tags: ..., attributes: ...)` rather than manual escaping — see `app/models/message.rb`.

## Controllers

Use strong parameters, and keep business logic out of the action itself — encapsulate it in a method, or for anything non-trivial, a service object (see Service Objects below). There's no enforced naming/location convention for the strong-parameters method itself; a private `<noun>_params` method is the most common pattern.

### Exception handling

Prefer letting exceptions bubble up and surface early over broad rescues — this mirrors the Background Async Jobs convention below. If you do rescue an exception, rescue a specific exception class intentionally (never a bare `rescue` or `rescue StandardError`), and forward to Sentry if the rescue means the exception would otherwise go unreported.

## Authorization

### Authorization on a record

When authorizing an action on an individual record, for example a Client, use a resource policy.

```ruby
policy = user.policy_for(client)
not_authorized! unless policy.can_view?
```

### Authorization on a controller action

Keep authorizations at the top of the controller. Use the `authorize_with()` helper, preferably with a policy class.

```ruby
class ProjectsController < ApplicationControllerV2
  authorize_with { project_policy.can_view? }
  authorize_with(only: [:edit, :update]) { project_policy.can_edit? }

  helper_method def project_policy
    current_user.policy_for(@project)
  end
```

Note, the deprecated legacy pattern uses "require_can_*" helpers. However these do not provide granular enough checks going forward

```ruby
class ProjectsController < ApplicationController
   # deprecated, use authorize_with instead
   before_action :require_can_edit_projects!, only: [:edit, :update]
```

### Authorization on a scope

We should use `ArModel.viewable_by(user)`. Note there are variations of this scope in the code base but we should prefer `viewable_by` over visible_by or other variations.

## Tracking PII

If your model could store Personally Identifiable Information (PII), use the `pii_attr` helper to catalog it. Why track PII? It allows us to inventory and potentially scrub PII from our database if needed

For example, if your model has name, dob, and ssn cols:

```ruby
  module MyReportClient GrdaWarehouseBase
    include HasPiiAttributes
    pii_attr :first_name
    pii_attr :last_name
    pii_attr :dob
    pii_attr :ssn
    pii_attr :description, as: :free_text, level: 2 # sensitive notes
  end
```

Note, there is a similar pattern for tracking PHI on in the health-related classes

### Storing credentials

credentials and related configuration should be stored in the `GrdaWarehouse::RemoteCredential` table. This is an STI model, so use the appropriate subclass (s3 etc).

## Models

### Concerns

Name a concern for what it does, not with a `_concern`/`_mixin`/`_behavior` suffix (e.g. `Filterable`, `HasPiiAttributes`, `ClientSearch`). Standard shape: `extend ActiveSupport::Concern`, an `included do ... end` block for scopes/associations/callbacks, and a nested `module ClassMethods` for class-level methods.

### Callbacks

Use `before_save`/`after_create`/etc. sparingly, and only for cross-cutting side effects tied to persistence itself (cache invalidation, maintaining a derived/system record, firing a notification) — never for core business logic. If a callback is doing domain work, extract it to an explicit method call or a service object instead.

### HUD-coded fields: don't use `enum`

Rails `enum` doesn't fit HUD's coded/lookup fields (race, ethnicity, project type, destinations, etc.) — HUD values change between fiscal years/spec versions and include multi-valued and "unknown" sentinel codes that don't map cleanly onto a Rails enum. Use the version-aware dispatcher instead:

```ruby
HudHelper.util(hud_version).races
```

`HudHelper.util(version)` resolves to the correct `HudUtility2024` / `HudUtility2026` / `HudUtilityLegacy` module for the version in play.

### Single Table Inheritance

Use STI when it fits, but not automatically. It's often the wrong fit for classes that are versioned by year (see Driver Architecture below), or that you may want to remove entirely in the future: Rails raises if a `type` column value exists in the database with no corresponding class in the codebase, so you can't safely delete an old STI subclass just because you're done adding new records with it. Where old typed rows still exist but the class is otherwise retired, keep an explicit stub subclass rather than deleting it outright.

## Service Objects

Prefer a service object over embedding complex logic directly in a model or controller. This is an intentional, ongoing shift in the codebase — encourage it over adding more logic to an existing class. The convention is `SomeService.call(...)`, implemented as `def self.call(...) = new(...).call` plus an instance `#call`:

```ruby
class Idp::AdminUserCreator
  def self.call(...) = new(...).call

  def call
    ...
  end
end
```

Where the class lives (`app/models/` vs `app/services/`) is not enforced — decide case-by-case. Both directories are in active use.

## Installation-specific configuration

Use the database to store application-specific configuration if possible. Avoid using the ENV as it's harder to manage. You can use the generic `AppConfigProperty` to store configuration that has no other more natural home.

## Database Queries

For complex active record queries, prefer to use Arel over plain text or hash syntax. Using arel keeps our code more database agnostic. Also the nested hash syntax has had some incompatibilities with case-sensitive fields and table names in our the HUD tables.

Where possible prefer ActiveRecord `merge` over Arel.

**Good**
```
GrdaWarehouse::Hud::Enrollment.joins(:client).merge(GrdaWarehouse::Hud::Client.veteran)
```
**Less Good**
```
GrdaWarehouse::Hud::Enrollment.joins(:client).where(c_t[:VeteranStatus].eq(1))
```

Rely on ActiveRecord relationships over manual table joins.

Avoid passing raw SQL strings to `update_all` / `delete_all` / `update_counters`; on joined relations (e.g. the `.hmis` scope) Rails 8.1 aliases the table and bare columns become ambiguous. See [ActiveRecord, Arel, and Query Best Practices](active-record-arel-and-queries.md) for the full rationale, the range-syntax preference, and the `Queries/UnsafeBulkUpdateSql` cop.

### Scope naming

Reuse existing scope names rather than inventing synonyms — `.active`, `.ordered`, `.for_user(user)`, and `.newest_first` all recur across models for the same job.

## Background Async Jobs

All jobs should inherit from BaseJob.

Allow exceptions to bubble-up so that they can be reported to sentry. Avoid code that ignores or swallows exceptions.

Avoid using errors for control-flow. When jumping out of deeply nested methods, first consider if normal control flow can be used. If not, use catch and throw rather than an exception.

## Driver Architecture

### Versioned report generators

HUD report drivers that implement a versioned report (APR, CAPER, SPM, HIC, etc.) namespace generator logic by federal fiscal year (`Fy2020`, `Fy2023`, ... `Fy2026`) rather than mutating a single generator in place, registered separately in the driver's feature initializer. This keeps old report years reproducible while new HUD spec years are added as new sibling code rather than edits to already-validated logic.

### Extending `HudReports::UniverseMember`

A new report driver adds its own `belongs_to` to the shared `HudReports::UniverseMember` model via an `extensions/hud_reports/universe_member_extension.rb` concern, included once from the core model. This is the current convention for a new report driver to follow — worth noting it may not be the ideal long-term design, but it's what's here today, so match it rather than inventing a new approach.

### Driver-local `BaseController`

HUD-report drivers define their own `<Driver>::BaseController < ::HudReports::BaseController` (not `ApplicationController` directly), and all other controllers in that driver inherit from it. Drivers outside the report framework may inherit `ApplicationController` directly instead — follow whichever base your driver extends.

### `RailsDrivers.loaded` is legacy

`RailsDrivers.loaded << :driver_name` in a driver's feature initializer is boilerplate carried forward through technical debt — all drivers are always loaded. `RailsDrivers.loaded.include?(...)` is legacy code slated for cleanup; do not write new code that gates behavior on it.

## GraphQL

### Field-level authorization: `access_field` + `bool_field`

Expose granular, UI-facing permission booleans via `access_field` on a type, with `bool_field` calls inside reusing a memoized `policy` helper:

```ruby
define_method(:policy) { @policy ||= policy_for(object, policy_type: :hmis_organization) }

access_field do
  bool_field(:can_edit?) { policy.can_edit? }
end
```

This is the current standard. Legacy `root_can`/`composite_perm`/`can` still exist and aren't automatically violations — don't flag them on sight, but write new fields this way.

### Three layers of authorization

A GraphQL type can be authorized at three layers, each serving a different purpose:

1. `viewable_by(user)` scope — the primary defense, applied when building the initial relation.
2. `self.authorized?(object, ctx)` override — a secondary, defense-in-depth guard re-checking a policy per-object before it's returned to the client at all.
3. `access_field` / `bool_field` — UI-facing booleans for what the client is allowed to *do*, not a security boundary on their own.

### Mutation authorization

Mutations authorize imperatively, not declaratively: scope the target with `viewable_by(current_user)` (or an equivalent finder), then raise via `access_denied!` if not found or a `policy_for(...).can_x?` check fails.

```ruby
unit_group = Hmis::UnitGroup.viewable_by(current_user).find_by(id: id)
access_denied! unless unit_group
access_denied! unless policy_for(unit_group.project, policy_type: :hmis_project).can_manage_units?
```

Subclass `CleanBaseMutation`, not `BaseMutation` — `BaseMutation` is legacy Relay-flavored scaffolding kept for compatibility.

### Avoiding N+1s in resolvers

Read associations inside resolvers/mutations through `load_ar_association` / `load_ar_client_association` (from `GraphqlApplicationHelper`), not plain AR association methods — GraphQL field resolution fans out per-object, so a plain `object.client` call becomes an N+1 across the result set. Use the `_client_` variant for anything touching `Client`, since it also preloads authorization dependencies.

## Testing

Use factories if possible to create test objects rather than the active record classes themselves. This reduces boilerplate code in our tests.

## Background Reports

Where possible, reports that run in the background should use some shared infrastructure.  For official HUD reports, they should use `HudReports::ReportInstance` and follow patterns used in other HUD reports, like including `render 'hud_reports/index'` and `= render 'hud_reports/show'` in their index and show pages to provide a consistent user experience.  For warehouse reports, `SimpleReports::ReportInstance` should be used where possible, and `= render 'common/background_report/history_filter'`
and `= render 'common/background_report/history_table'` should be included to present a consistent filtering and history experience.
