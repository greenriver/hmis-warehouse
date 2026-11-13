---
sources:
  - drivers/hmis/app/graphql/hmis_schema.rb
  - drivers/hmis/lib/tasks/graphql.rake
  - drivers/hmis/app/controllers/hmis/graphql_controller.rb
  - drivers/hmis/app/graphql/mutations/clean_base_mutation.rb
  - drivers/hmis/app/graphql/resolvers/validation_errors.rb
  - drivers/hmis/app/graphql/concerns/graphql_application_helper.rb
---

# HMIS GraphQL

The HMIS API is a single GraphQL endpoint served by `drivers/hmis`. This repository holds the API and models; the React client lives in the separate `hmis-frontend` repository. Authorization inside the schema is covered in [HMIS permissions](hmis-permissions.md); resolver and mutation conventions (`CleanBaseMutation`, loader helpers, N+1 tests) are in [Code patterns and conventions](../../code_patterns_and_conventions.md#graphql).

## The checked-in schema

`drivers/hmis/app/graphql/schema.graphql` is a generated dump of `HmisSchema`, and the front-end build generates its types from it. Introspection is disabled outside development, so the dump is the only schema source for tools such as codegen.

- Any change to a type, argument, enum, or description changes the file. Run `bundle exec rake driver:hmis:dump_graphql_schema` and commit the result in the same PR.
- The task exits with status 1 when the file changed. CI runs it ("Check HMIS GraphQL schema"), so a type change without a regenerated dump fails the build.
- Don't edit the file by hand.
- Rake tasks under `drivers/hmis/lib/tasks/` are namespaced `driver:hmis:` automatically, even where the `.rake` file has no `namespace` block.

## Validation errors are data

Mutations return validation failures in the payload's `errors` field instead of raising. Errors from `HmisErrors::Errors` and ActiveModel are normalized to a common shape (attribute, message, type, severity, `link_id`, and so on) by `Resolvers::ValidationErrors`. Only authorization failures (`access_denied!`) and unexpected exceptions surface as top-level GraphQL errors.

- Don't `raise` for a validation failure in a mutation. Collect errors and return them on the payload.
- Outside development and test, an uncaught exception renders as HTTP 500 with a generic message. `HmisErrors::ApiError` carries its own display message, and a stale-object error maps to a specific code. Requests that crash write no activity log row.

## Gotchas

- **A nil from a non-null field blanks its parent.** A `null: false` field whose resolver returns nil (for example a filtered-out record) does not raise in Ruby. The gem adds an execution error and nulls the nearest nullable ancestor, which can blank a whole page. Specs using `post_graphql` raise on any `errors` entry, so the failure shows as a raised message rather than a status code.
- **Root resolvers need their own data source scope.** A root resolver for a model with no `viewable_by` must scope to `current_user.hmis_data_source_id` itself, as the service type resolvers do with `in_data_source`. A bare `find_by(id:)` or `.all` returns records from other HMIS installations sharing the database.
- **Client loads need the client variants.** `load_ar_association` returns an already-loaded association directly, but the `_client_` variants always go through the dataloader so the client policy preloader runs. Use them for anything returning a `Client`.
- **Mixing pagination shapes fails.** Returning an in-memory array to a scope-paginated field, or the reverse, fails at pagination. Use `array_page_type` when paginating an array deliberately.
- **Depth and complexity limits.** `HmisSchema` caps query depth and complexity. Set `HMIS_GQL_LOG_DEPTH_COMPLEXITY=1` in development to log each query's values when tuning the limits.
- **Legacy `BaseMutation` subclasses remain.** Don't add another.
