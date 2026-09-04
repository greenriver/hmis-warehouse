# Warehouse Auth Policies

Warehouse Auth Policies contain the business rules for determining user access to warehouse resources such as clients, projects, and data sources.

## Overview

The authorization system decouples permission checks from the underlying data models and the specific authentication mechanism (Legacy Role-based or ACL-based). Policies are initialized with a context object that resolves permissions for the current user.

## Architecture

The system consists of three main components:

- **Entry Point**: `User#policy_for(resource)` or `User#reporting_policy_for_project(project_id)` are the primary ways to obtain a policy.
- **Context Objects**: `UserAclContext` and `UserLegacyContext` encapsulate permission lookups. They provide a common interface for policies to query permissions without knowing how they are stored or resolved.
- **Context Loaders**: Specialized objects (e.g., `ClientRoiLoader`) that provide cached data loading for policies to avoid N+1 queries.
- **Policies**: Concrete classes inheriting from `BasePolicy` that define domain-specific authorization logic.

### Relationship Diagram

```mermaid
graph TD
    User -->|policy_for| Policy
    Policy -->|queries| Context
    Context -->|resolves| ACLs[ACL System]
    Context -->|resolves| Legacy[Legacy System]
    Context -->|uses| Loaders[Context Loaders]
    Loaders -->|optimizes| DB[(Database)]
    Policy -->|validates| Resource
```

## Policy Implementation

Policies are located in `app/models/grda_warehouse/auth_policies/`.

- `BasePolicy`: Abstract base class providing common initialization and validation helpers.
- **Resource Policies**: for warehouse resources (e.g., `ProjectPolicy`, `SourceClientPolicy`, `DataSourcePolicy`).
- **Specialized Policies**: optimized for controlling access to sensitive data in reporting contexts (e.g., `ProjectPiiPolicy`).

## Usage

Policies are typically invoked through the `User` model.

```ruby
# Get a policy for a specific project
policy = current_user.policy_for(@project)
policy.can_view?
policy.can_edit?

# Get a PII policy for reporting
pii_policy = current_user.reporting_policy_for_project(project_id)
pii_policy.can_view_full_ssn?
```

### Preloading

When checking policies for multiple resources (e.g., in a list view), the context provides helpers to preload dependencies to avoid N+1 queries.

```ruby
context = current_user.policy_context

# Preload resource permissions
context.preload_some_dependencies(resource_ids)

# Preload through a context loader
context.some_loader.preload(resource_ids)
```

## PII Provider Instantiation

`GrdaWarehouse::PiiProvider` is built a few different ways depending on whether a policy already exists and whether restriction still needs to be applied.

`Client#pii_provider(user:)` is the standard entry point for a single client shown in isolation (e.g. the client dashboard). It resolves the user's policy for the client and applies restriction in one call.

```ruby
pii = client.pii_provider(user: current_user)
```

`Client#project_pii_provider(project:, user:, mode:)` is the entry point for project-scoped reporting, where `User#reporting_policy_for_project` already wraps the resolved policy with `PiiProvider.restrict`.

```ruby
pii = client.project_pii_provider(project: project, user: current_user, mode: :browse)
```

`GrdaWarehouse::PiiProvider.new(client, policy: GrdaWarehouse::PiiProvider.restrict(allow_policy, restricted: ...))` is used instead of `client.pii_provider(user:)` when the policy isn't sourced from resolving a `User` against the client. This occurs when a `CohortPiiPolicy` or `AllowPiiPolicy` is applied per row of a cohort or bulk report, or when restriction must be preloaded and checked across many rows rather than recomputed per client.

```ruby
policy = GrdaWarehouse::PiiProvider.restrict(
  GrdaWarehouse::AuthPolicies::CohortPiiPolicy.new(user: current_user),
  restricted: current_user.policy_context.client_restricted?(client_id),
)
pii = GrdaWarehouse::PiiProvider.new(client, policy: policy)
```

Most HUD report drilldowns and exports (APR, HOPWA CAPER, PIT, SPM, PATH, HMIS Data Quality Tool) don't have a live `Client` record, they render a denormalized, per-report `HudReports::ReportClientBase` subclass row snapshotted when the report ran. Instead of using the client PII provider they call `User#reporting_policy_for_project(project_id:, mode:, client_id:)` and pass the resulting policy to that row's own `#display_value`, which fans it out per column into `PiiProvider.viewable_name`/`viewable_ssn`/`viewable_dob`/`viewable_hiv_status`, without ever constructing a `PiiProvider` instance.

```ruby
pii_policy = current_user.reporting_policy_for_project(project_id: client.project_id, client_id: client.destination_client_id_for_pii)
client.display_value(:first_name, pii_policy: pii_policy)
```

`GrdaWarehouse::PiiProvider.from_attributes(policy:, first_name:, last_name:, middle_name:, dob:, ssn:, image:)` is used when there's no AR client record to wrap. For a plucked hash row a `PiiProviderRecordAdapter` is used so the same `policy`-driven redaction can be applied.

```ruby
policy = GrdaWarehouse::PiiProvider.restrict(GrdaWarehouse::AuthPolicies::CohortPiiPolicy.new(user: current_user), restricted: restricted)
provider = GrdaWarehouse::PiiProvider.from_attributes(policy: policy, first_name: c[:FirstName], last_name: c[:LastName], dob: c[:DOB], ssn: c[:SSN])
```

## PII Redaction

`GrdaWarehouse::PiiProvider` (`app/models/grda_warehouse/pii_provider.rb`) mediates name, SSN, DOB, photo, and HIV status display for a client, given a duck-typed `policy:` object (any object implementing `can_view_name?`, `can_view_full_ssn?`, `can_view_partial_ssn?`, `can_view_full_dob?`, `can_view_photo?`, `can_view_hiv_status?`, `can_view?`). Most PII display paths in the app, including the client dashboard, HUD report drilldowns/exports (APR, CAPER, HOPWA CAPER, PIT, SPM, PATH, HMIS Data Quality Tool), and cohort grids, and the `HomelessSummaryReport`, `MaYyaReport`, `WarehouseReport::Outcomes`, and `CoreDemographicsReport` warehouse reports, resolve a policy object and ask it these questions before showing a value.

`can_view_partial_ssn?` gates the masked (`XXX-XX-1234`) SSN, distinct from `can_view_full_ssn?`'s unmasked one. It is `true` for every policy except a restricted client's. Restriction means no SSN at all, matching `Hmis::AuthPolicies::HmisClientPolicy::Instance#can_view_partial_ssn?`.

### HMIS client restriction

An HMIS source client marked restricted (see [HMIS Restricted Records](../hmis/hmis-restricted-records.md)) is treated as a PII block in the warehouse: `GrdaWarehouse::PiiProvider.restrict(policy, restricted:)` wraps any resolved policy in a `RestrictedPolicy` that forces every PII predicate to `false`, regardless of what the underlying policy would grant. There is no warehouse-side override permission; the only way to restore visibility is for HMIS staff to unmark the client. A `RestrictedRecord` placed directly on the destination client id (there is no UI for this today, but the polymorphic `restrictable_id` allows it) restricts the same way.

**Loading strategy.** Restriction are expected to be applied infrequently and is not a bulk visibility mechanism. `GrdaWarehouse::AuthPolicies::ContextLoaders::RestrictedClientLoader` loads the full set of restricted client ids the first time a lookup occurs. This process uses three bounded queries. The data is memoized on `UserBaseContext`, which is memoized on `User#policy_context`. This ensures a request or background job only performs the load one time. The methods `client_restricted?` and `restricted?` function as a standard Set membership test.

**Per-request snapshot** The set of restricted clients is memoized on the `User` instance for the life of a request or job.  Client's who are marked restricted during a long-running task (HMIS CSV export, or similar) will remain unrestricted in that export.

**Not bounded data source.** HMIS's `restricted_ids_in_data_source` is limited to the data in a single data source on the HMIS front-end.  When we extend the client restriction to the warehouse, we restrict any related source and destination record.

### Search

Restricted clients are also excluded from every warehouse-side client search path by name or SSN — window/admin search, the client-edit merge-candidate search, the new-client duplicate check, cohort "Add Client to Cohort" search, `potential_matches`, the chronic/HUD-chronic report name filters, and the Coordinated Entry client proxy search. DOB search and exact-ID/PersonalID lookup are unaffected, matching the general rule that restriction blocks PII display and search-by-PII, not record access.

`GrdaWarehouse::Hud::Client.hmis_restricted_source_client_ids` computes the excluded id set (both source and destination ids, since restriction is tracked per source client but some search scopes can return destination rows). `ClientSearch#text_searcher` (`app/models/concerns/client_search.rb`, shared by `GrdaWarehouse::Hud::Client` and `Hmis::Hud::Client`) takes this set through an optional `exclude_ids_for_name_and_ssn:` keyword, applied only to the SSN-exact-match and free-text name-matching branches; the keyword defaults to `nil`; `Hmis::Hud::Client`'s own search methods never pass it, so `Hmis::Hud::Client.searchable_to` (see [HMIS Restricted Records](../hmis/hmis-restricted-records.md)) is unaffected by this mechanism. `GrdaWarehouse::Hud::Client.strict_search` excludes restricted destination clients from its final result set entirely, since its 3-of-4-criteria match can never be satisfied by DOB alone. The one search path that doesn't go through `text_searcher` — the new-client duplicate check (`ClientController#look_for_existing_match`) — applies the same exclusion directly to its SSN and name clauses.

### OP Analytics and Superset `analytics.client_piis`

The Scenic view `analytics.client_piis` (`db/views/analytics_client_piis_v02.sql`) enforces PII redaction for HMIS Restricted clients.  The view joins `hmis_restricted_records` and replaces `FirstName`, `MiddleName`, `LastName`, `NameSuffix`, and `SSN` with the literal `'Redacted'` when an active restriction row exists for the source client (`restrictable_type = 'Hmis::Hud::Client'`, `restrictable_id` matching the source `Client` id, `deleted_at IS NULL`). `DOB` is not redacted in this view so that the transformations can calculate age. Row-level security in the `superset-sync` repository governs which clients a given Superset user can query.

### Known limitations

Coverage is bounded by what actually calls into `PiiProvider`/the `reporting_policy_for_*` methods. The following do not honor restriction, and continue to show a restricted client's real PII:

- Toggle-gated exports whose rows are plucked hashes/arrays rather than `Client` AR records (tracked for follow-up batches; see `dev/build_docs/restricted_clients/`) still show a restricted client's real PII regardless of the toggle — only `Client`-AR-record rows were converted to per-client restriction so far.
- `ApplicationHelper#ssn`/`#dob_or_age` — gate only on the viewer's general permission on an already-extracted raw value, with no per-client hook (used outside report/dashboard/cohort contexts, e.g. client edit forms).
- The global `User#can_view_hiv_status?` role permission (distinct from `PiiProvider`'s HIV redaction) — used in roughly ten places (disability rollup views, CAS export, report filters, HUD report cell/drilldown gating) with no client-level scoping at all.
- `MaYyaReport`'s `details.xlsx.axlsx` — the HTML view (`details.haml`) passes `client_id:` into `reporting_policy_for_project` and is restriction-aware, but the Excel export's equivalent call omits `client_id:`, so restriction never applies to that one export. (`HomelessSummaryReport`, `CoreDemographicsReport`, `WarehouseReport::Outcomes`, and the Active Veterans report (`warehouse_reports/active_veterans`) are fully wired via `reporting_policy_for_client`/`PiiProvider.restrict`, both html and xlsx — not a gap. Active Veterans resolves the policy from the client rather than `project_id: nil`, so a non-restricted client's name/DOB/SSN show only when the viewer's roles grant them on one of that client's enrolled projects.)
- `warehouse_reports/cas/non_hmis_clients` renders raw candidate name/SSN/DOB from an external CAS import with no warehouse client id to gate on — these rows aren't yet linked to any warehouse identity, so there's no restriction to check.
