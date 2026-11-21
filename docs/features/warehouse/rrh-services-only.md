---
sources:
  - app/models/grda_warehouse/hud/project.rb
  - app/models/concerns/cas_client_data.rb
  - app/models/grda_warehouse/warehouse_clients_processed.rb
  - drivers/performance_measurement/app/models/performance_measurement/report.rb
---

# RRH: Services Only

HUD FY2024 added `Project.RRHSubType`. RRH projects with sub-type 1 (Services Only) don't provide housing assistance themselves, but HUD still collects a Housing Move-in Date when the household moves into permanent housing paid for by another source. This doc covers how warehouse logic treats those enrollments. It is not yet a complete inventory of every place that checks the sub-type.

## The warehouse rule

An RRH enrollment of any sub-type with a move-in date counts as permanent housing from the move-in date. An RRH: Services Only enrollment without a move-in date never counts as in housing.

Logic falls into two groups.

**Enrollment-level checks follow the rule.** They look at the move-in date and don't check the sub-type:

- Service history marks PH days on or after the move-in date `homeless: false`. See [Service History](service-history.md).
- CAS `enrolled_in_rrh` (in `CasClientData`) and `GrdaWarehouse::Hud::Client#moved_in_with_ph?`.
- `GrdaWarehouse::Hud::Enrollment.housed`.
- The HMIS client `client_is_housed` check in `Types::HmisSchema::Client`.

**Project-level checks exclude RRH: Services Only regardless of move-in date.** `GrdaWarehouse::Hud::Project.residential` counts an RRH project as residential only when `RRHSubType` is 2 (housing) or blank, since older data often lacks the sub-type. Logic built on it excludes Services Only projects:

- The "Enrolled in PH" cohort column (`WarehouseClientsProcessed#enrolled_permanent_housing`).
- The "Ongoing RRH Enrollments" cohort column (`WarehouseClientsProcessed#last_rrh_visit`).

## Performance Measurement bed utilization

Performance Measurement counts a permanent housing bed night only on or after the move-in date. RRH: Services Only nights never count, because HUD says those projects have no bed inventory.

## Related

- [Service History](service-history.md): the `homeless: false` flag on PH days after move-in.
- [Cohorts](cohorts.md): the cohort columns above.
