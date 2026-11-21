---
sources:
  - lib/util/hud_utility_2026.rb
  - app/models/grda_warehouse/hud/project.rb
  - app/models/grda_warehouse/service_history_enrollment.rb
  - app/models/concerns/service_history_service_concern.rb
  - drivers/hmis/app/models/hmis/hud/project.rb
  - app/models/concerns/cas_client_data.rb
  - app/models/grda_warehouse/warehouse_clients_processed.rb
---

# Project Type Classification

HUD assigns every project one `ProjectType`. Warehouse logic seldom asks about a single type. It asks whether a project is residential, homeless, or permanent housing. This doc covers the groupings that answer those questions, defined in `HudHelper.util`, and the scopes and predicates built on them in `GrdaWarehouse::Hud::Project`, `GrdaWarehouse::ServiceHistoryEnrollment`, and `GrdaWarehouse::ServiceHistoryService`. The HUD code lists themselves, and how `HudHelper.util` picks a fiscal-year version, are in [HUD Utility Versions](hud-utility-versions.md).

## The groupings

Two hand-written hashes in `HudHelper.util` map a group key (`:es`, `:th`, `:ph`, `:rrh`, and so on) to a list of project type numbers:

- `residential_project_type_numbers_by_code` holds the residential groups.
- `performance_reporting` holds the same groups plus the non-residential ones (`:ce`, `:other`, `:day_shelter`, `:prevention`, `:services_only`).

The two hashes repeat the residential entries, and `permanent_housing_project_types` is a third hand-written copy of the PH types. A change to one has to go into the others. The other named lists in `HudHelper.util`, such as `residential_project_type_ids`, `homeless_project_types`, and `literally_homeless_project_types`, are built from `residential_project_type_numbers_by_code`. Some of their memberships are easy to get wrong:

- `homeless_project_types` includes TH. `literally_homeless_project_types` does not, and `chronic_project_types` returns the same list as `literally_homeless_project_types`.
- `residential_project_type_ids` includes SO. See [Why Street Outreach is residential](#why-street-outreach-is-residential).
- The PH group, which `permanent_housing_project_types` and `project_types_with_move_in_dates` both return, includes RRH.

`project_types_without_inventory` is a separate literal list of the types HUD collects no bed inventory for. It works by project type only, so it misses RRH: Services Only, which also has no inventory (HMIS Data Standards 2.07).

## Scopes and predicates

`GrdaWarehouse::Hud::Project` and `GrdaWarehouse::ServiceHistoryEnrollment` generate a scope and a `?` predicate for each key in `performance_reporting`, such as `Project.rrh`, `Project#psh?`, and `ServiceHistoryEnrollment.es_nbn`. `Hmis::Hud::Project` does the same from `residential_project_type_numbers_by_code`. These generated scopes match on project type only. `GrdaWarehouse::ServiceHistoryService` has no generated scopes.

The generated scopes filter on `project_type_column`, which is `ProjectType` on `Project` and the copied `project_type` column on `ServiceHistoryEnrollment`. That lets one scope name work on both models. It also means a service history scope can't see a project attribute such as `RRHSubType` unless it joins the project.

Names that look alike mean different things:

- `Project.homeless` and `ServiceHistoryEnrollment.homeless` include TH, except that `ServiceHistoryEnrollment.homeless(chronic_types_only: true)` drops it. `hud_homeless` on both is ES, SO, and SH only.
- `ServiceHistoryService.homeless`, `literally_homeless`, and `non_homeless` read the stored day flags, not the project type. See [Service History](service-history.md).

## Why Street Outreach is residential

HUD's residential project types are 0, 1, 2, 3, 8, 9, 10, and 13 with sub-type 2 (HMIS Data Standards 2.02). Street Outreach (4) is not on that list. The warehouse's residential groups include it, because an SO enrollment records where someone was staying: HUD requires a Current Living Situation at project start (HMIS Data Standards 4.12). Code that needs HUD's own definition has to remove SO. For example, `Hmis::Hud::Project#allows_same_day_exit?` treats SO as an exception to the residential rule.

## RRH sub-type

HUD FY2024 added `Project.RRHSubType`: 1 is RRH: Services Only, and 2 is RRH: Housing with or without services. HUD says a Services Only project provides no ongoing rental assistance and has no bed inventory (HMIS Data Standards 2.02). It still records a Housing Move-in Date, because HUD requires one whenever a household moves into permanent housing, "regardless of funding source or whether the project is providing the rental assistance" (HMIS Data Standards 3.20).

RRH is the one case where project type alone doesn't decide the group:

- `Project.residential`, `hud_residential`, `residential_non_homeless`, and `hud_residential_non_homeless` count RRH only when `RRHSubType` is 2 or blank. Blank counts as residential because older data often lacks the sub-type. `non_residential` and `hud_non_residential` include sub-type 1.
- The `ServiceHistoryEnrollment` residential scopes join the project and apply the same rule.
- `ServiceHistoryService.residential` filters on the copied project type without a join, so it includes RRH: Services Only.
- The generated `rrh` and `ph` scopes, `ServiceHistoryEnrollment.permanent_housing`, and `permanent_housing_project_types` include every sub-type.

To ask about the sub-type directly, use `Project#rrh_sso_only?` or `Hmis::Hud::Project#services_only_rrh?`, and `HudHelper.util.rrh_sub_type_sso_only` for the code. `Project#rrh_with_housing?` is true for a blank sub-type too.

### Two answers to "is this client housed?"

Logic that checks the enrollment's move-in date and logic that checks the project's `residential` scope disagree about RRH: Services Only:

- **Move-in date logic** ignores the sub-type. A Services Only enrollment with a move-in date counts as housed from that date, and one without a move-in date never does. Examples include service history's `homeless: false` flag, CAS `enrolled_in_rrh`, `GrdaWarehouse::Hud::Client#moved_in_with_ph?`, and the housed check in the HMIS `Types::HmisSchema::Client#hud_chronic`.
- **Project-scope logic** excludes Services Only even after move-in. The "Enrolled in PH" and "Ongoing RRH Enrollments" cohort columns (`WarehouseClientsProcessed#enrolled_permanent_housing` and `#last_rrh_visit`) work this way.

Code that checks the sub-type itself picks one of these behaviors on purpose. For example, CAS `enrolled_in_rrh_pre_move_in` leaves out Services Only enrollments, so they are never treated as waiting to move in. Which kind of check a feature uses decides whether RRH: Services Only counts as housed.

## Related

- [HUD Utility Versions](hud-utility-versions.md): how `HudHelper.util` resolves a fiscal year, and the hand-written code a new version has to carry over.
- [Service History](service-history.md): the `homeless` and `literally_homeless` day flags derived from project type and move-in date.
- [Performance Measurement Dashboard](coc-performance-measurement-dashboard.md): bed-night counting for RRH: Services Only.
