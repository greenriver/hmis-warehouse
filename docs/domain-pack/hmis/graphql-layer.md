---
title: HMIS GraphQL layer
summary: "How the HMIS GraphQL API is assembled. HmisSchema, the single graphql controller, base type toolkit, CleanBaseMutation, dataloader helpers that prevent N+1s, validation errors as data, and the checked-in schema.graphql that the React front-end codegen consumes."
area: hmis
tags: [hmis, graphql, HmisSchema, GraphqlController, BaseObject, BaseField, CleanBaseMutation, load_ar_association, dataloader, Sources, ValidationError, schema.graphql, dump_graphql_schema, after_paginate]
sources:
  - drivers/hmis/app/graphql/hmis_schema.rb
  - drivers/hmis/app/graphql/schema.graphql
  - drivers/hmis/lib/tasks/graphql.rake
  - lib/tasks/driver_tasks.rake
  - drivers/hmis/app/controllers/hmis/graphql_controller.rb
  - drivers/hmis/app/controllers/hmis/base_controller.rb
  - drivers/hmis/app/graphql/types/hmis_schema/query_type.rb
  - drivers/hmis/app/graphql/types/hmis_schema/mutation_type.rb
  - drivers/hmis/app/graphql/types/base_object.rb
  - drivers/hmis/app/graphql/types/base_field.rb
  - drivers/hmis/app/graphql/types/base_input_object.rb
  - drivers/hmis/app/graphql/types/base_paginated.rb
  - drivers/hmis/app/graphql/types/paginated_scope.rb
  - drivers/hmis/app/graphql/types/paginated_array.rb
  - drivers/hmis/app/graphql/types/hmis_schema/validation_error.rb
  - drivers/hmis/app/graphql/types/hmis_schema/has_enrollments.rb
  - drivers/hmis/app/graphql/concerns/graphql_application_helper.rb
  - drivers/hmis/app/graphql/resolvers/base.rb
  - drivers/hmis/app/graphql/resolvers/validation_errors.rb
  - drivers/hmis/app/graphql/mutations/clean_base_mutation.rb
  - drivers/hmis/app/graphql/mutations/base_mutation.rb
  - drivers/hmis/app/graphql/mutations/create_client_alert.rb
  - drivers/hmis/app/graphql/sources/active_record_association.rb
  - drivers/hmis/app/graphql/sources/active_record_scope.rb
  - drivers/hmis/lib/hmis_errors/error.rb
  - drivers/hmis/lib/hmis_errors/errors.rb
  - drivers/hmis/spec/support/graphql_helpers.rb
  - docs/code_patterns_and_conventions.md
related:
  - authorization/hmis-graphql-authorization.md
  - hmis/data-model.md
  - hmis/forms.md
---

## Purpose

How the HMIS GraphQL API in `drivers/hmis/app/graphql/` is put together: the schema class, the one controller that executes queries, the base classes every type, field, input, and mutation inherit from, offset pagination, batch loading through `GraphQL::Dataloader`, validation errors returned as data, and the checked-in `schema.graphql` dump that CI keeps current. This repository is the API and the models only; the React client lives in the separate `hmis-frontend` repository and builds against `drivers/hmis/app/graphql/schema.graphql`. Authorization inside the schema (`viewable_by`, `self.authorized?`, `access_field`, `access_denied!`) is covered in `authorization/hmis-graphql-authorization.md` and is only linked from here.

## Entry points

- `POST /hmis/hmis-gql` (`drivers/hmis/config/routes.rb`) routes to `Hmis::GraphqlController#execute` (`drivers/hmis/app/controllers/hmis/graphql_controller.rb`). It is the only HTTP entry to the schema. A JSON array body is run as a multiplex (`HmisSchema.multiplex`); anything else is a single `HmisSchema.execute`. `GraphiQL` is mounted at `/hmis/graphiql` in development only.
- `HmisSchema` (`drivers/hmis/app/graphql/hmis_schema.rb`): `GraphQL::Schema` subclass with roots `Types::HmisSchema::QueryType` and `Types::HmisSchema::MutationType`.
- `Hmis::BaseController#attach_data_source_id` (`drivers/hmis/app/controllers/hmis/base_controller.rb`): a `before_action` on the GraphQL controller that binds the request host to an HMIS data source, sets `hmis_data_source_id` on the current and true user, and renders 403 when the person may not use that HMIS.
- Query context, built in `Hmis::GraphqlController#query_for_params`: `current_user`, `true_user`, `activity_logger` (`Hmis::GraphqlFieldLogger`). Every request also writes an `Hmis::ActivityLog` row with the operation name, variables, and `X-Hmis-*` headers.
- `bundle exec rake driver:hmis:dump_graphql_schema` (`drivers/hmis/lib/tasks/graphql.rake`, namespaced by `lib/tasks/driver_tasks.rake`): writes `HmisSchema.to_definition` to `drivers/hmis/app/graphql/schema.graphql`, then compares SHA1 before and after and calls `abort "Updated ..."` (exit status 1) when the file changed. CI runs this task as the "Check HMIS GraphQL schema" step in `.github/workflows/rails_tests.yml`, so a type change without a regenerated dump fails the build.
- `bundle exec rake driver:hmis:generate_graphql_enums['2026']` regenerates HUD enum types from `HudCodeGen`.

## How it works

### Schema

`HmisSchema` rejects abusive documents during static analysis with `max_depth 30` (introspection fields not counted) and `max_complexity 40_000`; the inline comment records the observed peak (about 17k for a 10-person household's entry assessments). `use GraphQL::Dataloader` enables batch loading. Introspection entry points are disabled outside development. `trace_with(GraphqlTraceBehavior)` feeds the activity logger; Sentry tracing is added when a traces sample rate is configured.

Hooks: `type_error` only calls `super`, so the gem default applies (an `InvalidNullError` becomes an entry in the response `errors` and null propagates to the nearest nullable ancestor; encoding errors raise). `resolve_type` on the schema raises `GraphQL::RequiredImplementationMissingError`; each union (`Types::HmisSchema::OmnisearchResult`, `Types::HmisSchema::SubmitFormResult`) defines its own `self.resolve_type`. `id_from_object` returns `object.to_gid_param` and `object_from_id` uses `GlobalID.find`, backing the Relay `node`/`nodes` fields that `QueryType` includes. `unauthorized_object` raises `GraphQL::UnauthorizedError`; `unauthorized_field` returns nil (details in `authorization/hmis-graphql-authorization.md`).

Set `HMIS_GQL_LOG_DEPTH_COMPLEXITY=1` in development to log each query's depth and complexity when tuning the limits.

### Types

`Types::BaseObject < GraphQL::Schema::Object` (`drivers/hmis/app/graphql/types/base_object.rb`) includes `GraphqlApplicationHelper`, sets `field_class Types::BaseField`, and adds: `page_type` / `array_page_type` (build a `<Name>sPaginated` type once per node type), `filter_options_type` / `available_filter_options`, `audit_event_type`, `access_field`, `hud_field` (infers GraphQL type and nullability from a `self.configuration` hash on types such as `Project`, `Inventory`, `ProjectCoc`), `skip_activity_log`, and `load_last_user_from_versions` / `load_created_by_user_from_versions` via `Sources::PaperTrailVersions`. A type usually wraps one `Hmis::Hud::*` record as `object`; resolvers read associations through the loader helpers, never directly.

`Types::BaseField` (`base_field.rb`) handles `default_value:`, the deprecated `permissions:` kwarg, the `authorize_with:` kwarg, `filters_argument`, and pagination. When a field's return type inherits from `Types::BasePaginated`, `PaginationWrapperExtension` adds `offset`/`limit` arguments, wraps the resolved relation in `Types::PaginatedScope` (defaults offset 0, limit 50; `nodes_count:` proc overrides `count`) or, for `Types::ArrayPaginated`, in `Types::PaginatedArray`, then calls the field's `after_paginate:` lambda with the page's nodes and the context. `Types::BasePaginated` exposes `nodes`, `nodes_count`, `pages_count`, `has_more_before`, `has_more_after`, `limit`, `offset`, and optionally `search_query_id`.

`Types::BaseInputObject` (`base_input_object.rb`) adds `hud_argument`, `transform_with(TransformerClass)`, and `to_params`, which runs the input through `Types::HmisSchema::Transformers::BaseTransformer` (a `to_h` by default) to produce model attributes.

### Mutations

Subclass `Mutations::CleanBaseMutation < GraphQL::Schema::Mutation` (`drivers/hmis/app/graphql/mutations/clean_base_mutation.rb`) and register the class on `Types::HmisSchema::MutationType` with `field :name, mutation: Mutations::Name`. The base declares `field :errors, [Types::HmisSchema::ValidationError], null: false, resolver: Resolvers::ValidationErrors`. Shape, from `drivers/hmis/app/graphql/mutations/create_client_alert.rb`: take `argument :input, SomeInput`, authorize imperatively, build attributes with `input.to_params`, collect problems in `HmisErrors::Errors` (`add(attribute, type, full_message:)`, `add_ar_errors(record.errors)`), and `return { errors: errors }` when any exist; otherwise save and return the payload key. `Resolvers::ValidationErrors` flattens `HmisErrors::Errors`, `HmisErrors::Error`, `ActiveModel::Error`, and `ActiveModel::NestedError` into `HmisErrors::Error` objects (`Error.from_ar_error`) that `Types::HmisSchema::ValidationError` renders with `attribute` (camelCased), `message`, `full_message`, `type`, `severity`, `link_id`, `record_id`, `section`, and `data`. Validation failures are therefore data on the payload, not top-level GraphQL errors; only `access_denied!` and unexpected exceptions surface as errors, which `Hmis::GraphqlController#handle_graphql_exception` renders as a 500 with a generic message outside development and test.

### Loading

Everything batches through `GraphQL::Dataloader`. `GraphqlApplicationHelper` (`drivers/hmis/app/graphql/concerns/graphql_application_helper.rb`) wraps the two general sources:

- `load_ar_association(object, :assoc)` -> `Sources::ActiveRecordAssociation`, which runs `ActiveRecord::Associations::Preloader` over the batch and returns each record's association. Returns the loaded association directly when it is already loaded and no `onload` is given.
- `load_ar_scope(scope:, id:)` -> `Sources::ActiveRecordScope`, `scope.where(id: ids)` indexed by id.
- `load_ar_client_association` / `load_ar_client_scope`: same, with an `onload` that calls `policy_context.preload_client_dependencies` on the loaded clients. Use these for anything returning `Client`.

Both sources key their batch on `to_sql` of relation arguments, so two calls with the same scope share one query. Custom `Sources::*` classes (`PaperTrailVersions`, `UserEntityAccessSource`, `CeReferralByInstanceIdSource`, and others) exist for lookups that are not a plain association or id lookup; call them with `dataloader.with(Sources::X, args).load(key)`.

Paginated fields preload authorization data for the page with `after_paginate`, for example `Types::HmisSchema::HasEnrollments` (`has_enrollments.rb`):

```ruby
after_paginate: ->(nodes, ctx) {
  ctx[:current_user].policy_context.preload_project_dependencies(nodes.map(&:project_pk))
},
```

N+1 test recipe (from `docs/code_patterns_and_conventions.md`; `post_graphql` is in `drivers/hmis/spec/support/graphql_helpers.rb`, `make_database_queries` comes from the `db-query-matchers` gem). Use tens of records, not one or two:

```ruby
it 'minimizes n+1 queries' do
  expect do
    response, result = post_graphql(limit: 50) { query }
    expect(response.status).to eq(200), result.inspect
    expect(result.dig('data', 'projects', 'nodes').size).to eq(50)
  end.to make_database_queries(count: 10..30)
end
```

Existing examples: `drivers/hmis/spec/requests/hmis/project_spec.rb`, `client_search_performance_spec.rb`.

## Key files

- `drivers/hmis/app/graphql/hmis_schema.rb:14` `max_depth`; `:15` `max_complexity`; `:23` `use GraphQL::Dataloader`; `:25` introspection disabled outside development; `:28` `type_error`; `:37` `resolve_type` raises; `:46` `id_from_object`; `:52` `object_from_id`; `:60` `unauthorized_object`; `:65` `unauthorized_field`.
- `drivers/hmis/app/controllers/hmis/graphql_controller.rb:16` `execute`; `:24` multiplex vs single; `:59` `query_for_params` builds context; `:95` `handle_graphql_exception`; `:128` activity log attributes.
- `drivers/hmis/app/controllers/hmis/base_controller.rb:51` `attach_data_source_id`.
- `drivers/hmis/lib/tasks/graphql.rake:6` `dump_graphql_schema`; `:17` `abort` when the SHA1 changed. `lib/tasks/driver_tasks.rake:14` adds the `driver:<name>:` namespace.
- `drivers/hmis/app/graphql/types/hmis_schema/query_type.rb:14` Relay `node`/`nodes`, then `Has*` includes. `mutation_type.rb` registers every mutation with `field :x, mutation:`.
- `drivers/hmis/app/graphql/types/base_object.rb:28` `page_type`; `:32` `array_page_type`; `:85` `hud_field`; `:106` `access_field`; `:133` `activity_log_object_identity`.
- `drivers/hmis/app/graphql/types/base_field.rb:21` `initialize` (`default_value`, `after_paginate`, `nodes_count`); `:46` `authorized?`; `:65` `PaginationWrapperExtension`; `:91` `after_paginate` call.
- `drivers/hmis/app/graphql/types/base_paginated.rb:14` `build`; `:35` `ArrayPaginated`. `paginated_scope.rb:13` defaults; `paginated_array.rb:11` array `nodes`.
- `drivers/hmis/app/graphql/types/base_input_object.rb:17` `transformer`; `:26` `hud_argument`; `:38` `to_params`.
- `drivers/hmis/app/graphql/concerns/graphql_application_helper.rb:25` `access_denied!`; `:52` `load_ar_client_association`; `:63` `load_ar_association`; `:72` `load_ar_scope`.
- `drivers/hmis/app/graphql/mutations/clean_base_mutation.rb:14` `errors` field; `base_mutation.rb:12` legacy Relay base; `create_client_alert.rb` worked example.
- `drivers/hmis/app/graphql/resolvers/validation_errors.rb:14` `resolve`; `resolvers/base.rb` empty `GraphQL::Schema::Resolver` base.
- `drivers/hmis/app/graphql/types/hmis_schema/validation_error.rb` payload fields.
- `drivers/hmis/lib/hmis_errors/errors.rb:22` `add_ar_errors`; `:33` `add`; `error.rb:43` `from_ar_error`.
- `drivers/hmis/app/graphql/sources/active_record_association.rb:19` `fetch` (Preloader); `active_record_scope.rb:15` `fetch`.
- `drivers/hmis/app/graphql/types/hmis_schema/has_enrollments.rb:27` `after_paginate`.
- `drivers/hmis/spec/support/graphql_helpers.rb:13` `post_graphql`; `docs/code_patterns_and_conventions.md` GraphQL section.

## Gotchas

- Two loading idioms coexist and both are `GraphQL::Dataloader`: the `load_ar_association` / `load_ar_scope` helpers (about 225 call sites) and direct `dataloader.with(Sources::X)` (about 13). A plain `object.assoc` inside a resolver is the N+1; the helpers are the fix.
- `load_ar_association` short-circuits when the association is already loaded, but not when `onload:` is given. `load_ar_client_association` therefore always goes through the dataloader so the client preloader runs.
- A `null: false` field whose resolver returns nil (for example a filtered-out record) does not raise in Ruby. The gem default `type_error` adds an execution error and nulls the nearest nullable ancestor, which can blank a whole page; `post_graphql` in specs raises on any `errors` entry, so the failure shows up as a raised message, not a status code.
- `Hmis::GraphqlController#handle_graphql_exception` rescues everything and renders HTTP 500 with a generic message outside development and test; `HmisErrors::ApiError` carries its own `display_message`, and `ActiveRecord::StaleObjectError` maps to `STALE_OBJECT_ERROR`. Requests that crash produce no `Hmis::ActivityLog` row.
- Any change to a type, argument, enum, or description changes `drivers/hmis/app/graphql/schema.graphql`. Run `bundle exec rake driver:hmis:dump_graphql_schema` and commit the result in the same PR; the task exits 1 when the file changed, which is what CI checks.
- `BaseObject.page_type` memoizes the first `include_search_query_id` value per node type; a later call with a different value is ignored.
- `hud_field` needs `self.configuration` on the type; without it the call is a plain `field` and a missing `type` raises `No type for ...`.
- `array_page_type` exists so an in-memory array is paginated deliberately. Returning an array to a scope-paginated field, or the reverse, fails at `offset`/`drop`.
- Introspection is off outside development; a tool that relies on it (GraphiQL, codegen) must run against a development server or the checked-in dump.
- Rake tasks under `drivers/hmis/lib/tasks/` are namespaced `driver:hmis:` by `lib/tasks/driver_tasks.rake`, even though the `.rake` file has no `namespace` block.

## Do not repeat

Repo-wide entry: `conventions/do-not-repeat.md` 13 (`BaseMutation`).

- `class Foo < BaseMutation` (`drivers/hmis/app/graphql/mutations/base_mutation.rb:12`, `GraphQL::Schema::RelayClassicMutation`). Instead: `< CleanBaseMutation` (`clean_base_mutation.rb:11`), for example `drivers/hmis/app/graphql/mutations/create_client_alert.rb`. Roughly thirty legacy subclasses remain; do not add another.
- A new `Sources::*` class for a plain association or id lookup. Instead: `load_ar_association` / `load_ar_scope` (`drivers/hmis/app/graphql/concerns/graphql_application_helper.rb:63`, `:72`), or the `_client_` variants when the result is a `Client`. Write a source only for a query shape they cannot express (`sources/paper_trail_versions.rb` is an example).
- `raise` for a validation failure in a mutation. Instead: collect in `HmisErrors::Errors` and `return { errors: errors }` so `Resolvers::ValidationErrors` renders it on the payload (`create_client_alert.rb`). `raise` / `access_denied!` is for authorization and unexpected state only.
- `object.assoc` or `Model.find` inside a resolver or `Has*` concern. Instead: the loader helpers, plus `after_paginate` for policy preloads on paginated fields (`has_enrollments.rb:27`).
- Editing `drivers/hmis/app/graphql/schema.graphql` by hand. Instead: change the Ruby type and run `driver:hmis:dump_graphql_schema`.

## Related

- `authorization/hmis-graphql-authorization.md`: `viewable_by`, `self.authorized?`, `access_field` / `bool_field`, `access_denied!`, `authorize_with:`, legacy `permissions:` and `current_permission?`.
- `authorization/hmis-permissions.md`: roles, collections, `Hmis::AuthPolicies::*`, `policy_context` preloaders used by `after_paginate`.
- `hmis/data-model.md`: the `Hmis::Hud::*` records that types wrap.
- `hmis/forms.md`: `SubmitForm` mutations and `FormProcessor`, the largest consumer of `HmisErrors::Errors`.
- `conventions/do-not-repeat.md`: entry 13.
- `docs/developer/drivers.md`: `driver:<name>:` rake namespacing.
