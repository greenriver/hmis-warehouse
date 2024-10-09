# Application Code Patterns and Conventions Guide

This document outlines the preferred patterns and conventions for code contributors. The goal is to improve code consistency and discoverability across the project.

This is a living document, please add or update patterns as appropriate. When adding new patterns, please include relevant details / rationale to help others understand how and why to use this pattern.

## Table of Contents

- [Server-side views](#server-side-views)
- [Authorization](#authorization)
- [Installation-specific configuration](#installation-specific-configuration)
- [Database Queries](#database-queries)
- [Background Async Jobs](#background-async-jobs)
- [Testing](#testing)

## Server-side views

### Rendering a resource list

For a collection of resources on an index page, prefer using a helper to render a table. This encapsulates the specifics of our pagination (pagy gem), reduces boilerplate, and improves UI consistency

```ruby
  render_paginated_list(scope: @data_sets, item_name: 'data set', list_partial: 'list')
```

### View Helper methods

Avoid defining global view helpers on ApplicationHelper unless the helper is truly global in scope. Instead constrain the helper to just the controllers where it is used.

### View Asset Management

When creating new assets, use esbuild in `app/javascripts` rather than asset pipeline.

## Authorization

### Authorization on a record

When authorizing an action on an individual record, for example a Client, use a resource policy.

```ruby
policy = user.policies.for_client(client)
not_authorized! unless policy.show?
```

### Authorization on a scope

We should use `ArModel.viewable_by(user)`. Not there are variations of this scope in the code base but we should prefer `viewable_by` over visible_by or other variations.

### Storing credentials

credentials and related configuration should be stored in the `GrdaWarehouse::RemoteCredential` table. This is an STI model, so use the appropriate subclass (s3 etc).

## Installation-specific configuration

Use the database to store application-specific configuration if possible. Avoid using the ENV as it's harder to manage. You can use the generic `AppConfigProperty` to store configuration that has no other more natural home.

## Database Queries

For complex active record queries, prefer to use Arel over plain text or hash syntax. Using arel keeps our code more database agnostic. Also the nested hash syntax has had some incompatibilities with case-sensitive fields and table names in our the HUD tables.

## Background Async Jobs

All jobs should inherit from BaseJob

Allow exceptions to bubble-up so that they can be reported to sentry. Avoid code that ignores or swallows exceptions.

Avoid using errors for control-flow. When jumping out of deeply nested methods, first consider if normal control flow can be used. If not, use catch and throw rather than an exception.

## Testing

User factories if possible to create test objects rather than the active record classes themselves. This reduces boilerplate code in our tests.
