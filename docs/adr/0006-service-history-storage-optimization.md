# ADR 0006 Service History Storage Optimization

## Status

- Current Status: Proposed
- Date of last update: 2025-10-23
- Decision-makers: OP Engineering Team

## Context

Our service history subsystem currently stores one row per client per day in the sharded `service_history_services` tables and mirrors that dataset in a materialized view. Most day-to-day attributes—project type, enrollment status, homeless flags—remain unchanged across large stretches of time, so we incur significant storage costs without corresponding analytical value. The materialized view amplifies the space requirements and elongates refresh cycles.

## Decision

Represent consecutive days with unchanged attributes as a single period row using PostgreSQL `daterange`; store start/end bounds alongside the associated service metadata instead of enumerating every day. Service history rebuild tasks will aggregate daily facts into periods during ingestion and consumers will query period records using range operators. Introduce a dedicated service history repository/utility that encapsulates the range-aware querying surface so callers do not reach for Active Record tables directly. With period records in place, the `service_history_services_materialized` view becomes redundant for per-client queries and can be removed from the architecture along with the shards of `service_history_services`.

## Impact Analysis

- **Cache generation (`GrdaWarehouse::WarehouseClientsProcessed`)**: Every homeless/chronically homeless/total day calculation is currently expressed as counts or extrema over the materialized view, with additional Arel subqueries to exclude overlapping project types. Converting to `daterange` means rewriting these queries to sum intersecting range durations instead of counting dates; the supporting code lives primarily in `StatsCalculator` (multiple methods using joins, the materialized view table name, and SQL fragments).
- **Project and report queries**: Dozens of scopes and joins (public reports, HUD APR/PIT generators, performance dashboards, CAS data) rely on `ServiceHistoryService.where(date: ...)`. These will need range-aware versions (`where('service_range @> ?', date)` or similar) plus helper methods for intersection-based counts.
- **Builder/rebuild pipeline**: Existing generation emits daily rows. We must update the service history rebuild tasks to collapse contiguous segments during generation .
- **Testing footprint**: Specs that assert row counts or rely on `ServiceHistoryService.count` (e.g., HMIS CSV importer specs, service history specs) will need updates to expect period rows and to verify range semantics.
- **Indexes and constraints**: The new `daterange` column will be backed by a per-client GiST index and an exclusion constraint to prevent overlapping periods, preserving query performance for range lookups.
- **External consumers**: We do not believe any third-party or analyst-facing tools query the existing shards or materialized view directly, but we will reaffirm that assumption during rollout and communicate the removal if we discover dependents.
- **Materialized view lifecycle**: Several jobs and rake tasks explicitly rebuild/refresh the view (`config/application.rb`, `lib/tasks/grda_warehouse.rake`, `RunDailyImportsJob`, and specs). Removing the view eliminates this overhead but requires pruning or updating those callsites.

## Consequences

- Reduces table and index size by collapsing long stretches of identical data into single records, lowering storage and maintenance overhead.
- Eliminates the need to refresh and monitor the materialized view, simplifying nightly jobs and removing a potential source of drift between primary and derived datasets.
- Requires refactoring existing queries and reporting code to use range-aware predicates (`@>`, `&&`, `lower`, `upper`) instead of simple equality on the `date` column.
- Introduces additional complexity into rebuild pipelines (must detect boundaries and merge periods carefully, especially around partial-day services and backfills).

## Alternatives Considered

- **Status quo (daily rows, improved hardware)**: Maintains compatibility but continues the growth curve and operational costs.
- **Archival pruning of historical rows**: Lowers storage but sacrifices fidelity for older analytics and does not address ongoing growth.
- **Conditional materialization (partial view subsets)**: Limits view size but leaves the base tables unchanged, preserving the primary cost drivers.

## Additional Info

- `docs/features/service_history.md`
