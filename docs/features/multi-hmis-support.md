# Multi-HMIS Support

This document describes how a single warehouse deployment supports **multiple OP HMIS installations**—each backed by its own data source—and how configuration and access are isolated per HMIS instance.

## Context

The warehouse already supports multiple data sources: it ingests data from different HMISs (including other vendors') and brings it together for reporting. That multi–data-source model is a core value proposition and a main function of the warehouse.

This document addresses the case where **multiple Open Path HMIS installations** are backed by a single warehouse deployment. Those OP HMIS installations may sit alongside data sources from other vendors' HMISs, or the deployment may include only OP HMIS data sources.

### Customer types

There are two primary customer types this supports:

1. **Multi-COC with isolation**: Each CoC operates its own isolated HMIS, backed by a separate Data Source. Data and users are isolated by CoC. The warehouse aggregates data from all CoCs for unified reporting and client history.
2. **Separate HMIS per agency**: Multiple Open Path HMIS installations (each its own data source) may exist *within* a single CoC. For example, when some agencies in that CoC use another vendor’s HMIS and one or more agencies have their own OP HMIS. Data source separation here is by agency/installation, not by CoC.

The main point here is that **data source separation is not necessarily CoC separation.** A single HMIS installation can serve multiple CoCs, one CoC, or a subset of a CoC projects, depending on the customer need.

### Design stance

- **One HMIS installation per data source** (each with its own domain).
- **Configuration** (forms, form instances, referral workflows, rules, etc.) is **fully isolated per data source**—no configuration “bleeding” across instances.
- Users may have access to multiple HMIS data sources; permissions are enforced **independently per data source**.

---

## How HMIS requests are routed to a data source

HMIS API requests (GraphQL and other HMIS controllers) determine **which data source** the request applies to from the **request host**. That binding happens before application logic runs, so all downstream code sees a single “current” HMIS data source for the request.

### Host → data source binding

1. **Host resolution**  
   The controller layer identifies the current HMIS “domain” from the request host:
   - In production: `request.host` (trusted value from Rack/Rails host resolution)
   - In development: the `X-Hmis-Dev-Host` header (so the dev frontend can simulate different HMIS domains).

   See `Hmis::BaseController#current_hmis_host`.

2. **Lookup data source by domain**  
   Each Open Path HMIS data source has an `hmis` attribute on `GrdaWarehouse::DataSource` storing the domain (e.g. `hmis-coc-a.example.com`). The controller looks up the data source for the domain identified by the request host.

3. **Attach data source to current user for the request**  
   A `before_action :attach_data_source_id` (used by the GraphQL controller, impersonations, client files, etc.) sets:

   `current_hmis_user.hmis_data_source_id = data_source_id`

   So for the rest of the request, the **current HMIS user** is bound to that data source. All HMIS authorization and data access use `current_user.hmis_data_source_id` (or equivalent) to scope to that single data source.

### Where this runs

- `Hmis::GraphqlController`
- `Hmis::ImpersonationsController`
- `Hmis::ClientFilesController`
- Other HMIS controllers that need request-scoped data source binding

The implementation lives in `Hmis::BaseController#attach_data_source_id`; controllers that need it include the appropriate `before_action`.

---

## Data model: HMIS data tied to a data source

All HMIS data (clients, enrollments, projects, organizations, etc.) is stored in tables that include a `data_source_id` foreign key to `GrdaWarehouse::DataSource`. That column ties each row to the specific HMIS data source it belongs to.

- **HUD entities** have `data_source_id`. Queries and resolvers scope by the current user’s `hmis_data_source_id`, so there is no cross–data-source exposure.

- **`viewable_by` scopes** combine permission-based filtering with a restriction to the user’s `hmis_data_source_id`. Convention: use these when you need “only records in this data source that the user may see.”

- **Auth Policies**  expect that the user has `hmis_data_source_id`, and raise an error if attempting to authorize data from a different data source.
  - **Global Policies** authorize the set of permissions the user has on *some* entity in that data source (see `#global_permissions`).  
  - **Instance Policies** authorize permissions against a particular record (often a project) and enforce that the data source matches the current data source. (See `#project_permissions`, `#organization_permissions`)

- **Object-level auth** on some GraphQL types (e.g. `HmisSchema::Client`) adds a final check, often via an instance policy. If a record from a different data source slipped through, this check prevents it from resolving.

---

## Configuration

Configuration (forms, form rules, referral workflows, auto-exit config, etc.) is intended to be scoped the same way as data: stored **per data source** and never shared across data sources. Today, some form and config tables are still shared or not fully scoped. Adding or enforcing `data_source_id` on those tables is part of the multi-HMIS work. (🟠TODO#6691)

---

## User access control / mis-assignment risk

Granting a user access to the **wrong** data source (e.g. an admin mistake) is a risk. We may want more infrastructure around user–agency relationship (or user-datasource relationship) on the access control side to address this. Moving to an IDP may provide other approaches to reducing this risk, for example using the IDP to manage which "applications" a user can reach.

**As implemented today**, if that mistake happens: the user may be able to log in and act on a **different** HMIS (another data source), but they are not accidentally exposed to data in what they consider “their own” system. The failure mode is “user sees another HMIS” rather than “user sees wrong data inside their HMIS.”

---

## Behavior summary

| Area | Behavior |
|------|----------|
| **Data source per HMIS** | Each HMIS installation is one data source; access is by its own domain. |
| **Request routing** | Host → `DataSource.hmis` → `attach_data_source_id` → `current_hmis_user.hmis_data_source_id` for the request. |
| **Data** | All HMIS data tables have `data_source_id`; access is scoped to the current request’s data source. |
| **Configuration** | Target state: fully isolated per data source (forms, form instances, workflows, rules). Some config still needs `data_source_id` and scoping. (🟠TODO#6691)|
| **Users** | A user can have access to multiple HMIS data sources; permissions are enforced independently per data source. |
| **User lists / admin** | User lists and selectors in an HMIS instance show only users active in that data source. (🟠TODO#8831)|
| **CoCs** | Each data source can define and manage its relevant CoCs independently. (🟠TODO#8829)|
| **Visual** | Each HMIS instance can have its own name and theme so users can tell which environment they’re in. (🟠TODO#8830)|

## Future possibilities

- **Shared configuration**: Not in scope today; all configuration remains strictly isolated. We may revisit sharing forms or config across data sources later.
- **Configuration portability**: Import/export or upload/download of configuration (e.g. forms) could allow replicating config across environments without building shared-config storage. (https://github.com/open-path/Green-River/issues/8880)
- **CoC-level segregation within one data source**: We could add improved support for multiple CoCs inside a single data source later, in cases where a 'softer' separation of CoCs within a single HMIS system is desired. (https://github.com/open-path/Green-River/issues/8823)
