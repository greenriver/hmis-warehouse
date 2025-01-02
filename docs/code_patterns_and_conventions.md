# Application Code Patterns and Conventions Guide

This document outlines the preferred patterns and conventions for code contributors. The goal is to improve code consistency and discoverability across the project.

This is a living document, please add or update patterns as appropriate. When adding new patterns, please include relevant details / rationale to help others understand how and why to use this pattern.

Note that this document may include code that is only in use in a handful of locations.  We recognize change can take time.  Sometimes patterns are added here after only being added to one of many locations in the codebase. Please follow these conventions and patterns if there is a relevent pattern listed.

## Table of Contents

- [Server-side views](#server-side-views)
- [Authorization](#authorization)
- [Installation-specific configuration](#installation-specific-configuration)
- [Database Queries](#database-queries)
- [Background Async Jobs](#background-async-jobs)
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

When creating new JavaScript assets, use esbuild in `app/javascripts` rather than asset pipeline.

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

## Background Async Jobs

All jobs should inherit from BaseJob

Allow exceptions to bubble-up so that they can be reported to sentry. Avoid code that ignores or swallows exceptions.

Avoid using errors for control-flow. When jumping out of deeply nested methods, first consider if normal control flow can be used. If not, use catch and throw rather than an exception.

## Testing

Use factories if possible to create test objects rather than the active record classes themselves. This reduces boilerplate code in our tests.

## Background Reports

Where possible, reports that run in the background should use some shared infrastructure.  For official HUD reports, they should use `HudReports::ReportInstance` and follow patterns used in other HUD reports, like including `render 'hud_reports/index'` and `= render 'hud_reports/show'` in their index and show pages to provide a consistent user experience.  For warehouse reports, `SimpleReports::ReportInstance` should be used where possible, and `= render 'common/background_report/history_filter'`
and `= render 'common/background_report/history_table'` should be included to present a consistent filtering and history experience.
