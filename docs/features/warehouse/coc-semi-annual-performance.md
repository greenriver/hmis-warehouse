---
sources:
  - drivers/continuum_semi_annual_performance/app/models/continuum_semi_annual_performance/report.rb
  - drivers/continuum_semi_annual_performance/app/models/continuum_semi_annual_performance/mid_year_report.rb
  - drivers/continuum_semi_annual_performance/app/models/continuum_semi_annual_performance/end_of_year_report.rb
  - drivers/continuum_semi_annual_performance/app/models/continuum_semi_annual_performance/sub_report_runner.rb
  - drivers/continuum_semi_annual_performance/app/models/continuum_semi_annual_performance/cell_snapshot.rb
  - drivers/continuum_semi_annual_performance/app/models/continuum_semi_annual_performance/row_definitions.rb
  - drivers/continuum_semi_annual_performance/app/models/continuum_semi_annual_performance/approval.rb
  - drivers/continuum_semi_annual_performance/app/models/continuum_semi_annual_performance/document_exports/exports_visible_report.rb
  - drivers/continuum_semi_annual_performance/app/helpers/continuum_semi_annual_performance/reports_helper.rb
  - drivers/continuum_semi_annual_performance/app/controllers/continuum_semi_annual_performance/warehouse_reports/reports_controller.rb
  - drivers/continuum_semi_annual_performance/config/rows.yml
  - drivers/continuum_semi_annual_performance/spec/models/continuum_semi_annual_performance/rows_yaml_shape_spec.rb
  - drivers/continuum_semi_annual_performance/config/initializers/continuum_semi_annual_performance_archival.rb
---

# CoC Semi-Annual Performance Reports

The CoC Mid-Year Performance Report and the CoC End of Year Performance Report summarize APR and CE APR results by project type for one CoC. Both live in `drivers/continuum_semi_annual_performance` as STI subclasses (`ContinuumSemiAnnualPerformance::MidYearReport`, `ContinuumSemiAnnualPerformance::EndOfYearReport`) of `SimpleReports::ReportInstance`, sharing the base class `ContinuumSemiAnnualPerformance::Report`. They appear under "Performance" in the report list.

This doc does not cover the APR and CE APR generators. See [hud-report-framework.md](hud-report-framework.md).

## Naming: Continuum in code, CoC in the UI

Code, paths, routes and tables say `continuum_semi_annual_performance`. Titles, headings, labels, flash messages and download filenames say "CoC". The app's inflections treat `CoC` as an acronym, so Rails would route a `coc_*` path to a `CoC*` constant and fail to autoload it. Existing `coc_code` and `coc_codes` names are unchanged.

## What a run does

A user picks one CoC (exactly one is required), a date range, and optionally narrows projects. The pickers (projects, organizations, data sources, project groups, project types) add together and apply only inside that CoC, as `HudFilterBase#effective_project_ids` does for HUD reports. The project type picker offers only the types the report uses (Mid-Year: ES, Homelessness Prevention, SO, RRH; End of Year: every performance reporting type, since any selected project feeds the CE APR) and pre-selects all of them, so an untouched form covers the whole CoC. The form lists the included projects and disables "Queue Report" when there are none; `create` enforces the same rule.

`ContinuumSemiAnnualPerformance::Report#run_and_save!` runs from `WarehouseReports::GenericReportJob`:

1. `SubReportRunner` resolves the selection to project ids once.
2. For each project type the report has (Mid-Year: ES, HP, SO, RRH; End of Year adds the CE tab, keyed `ce_tab` because it is not limited to project type 14) with at least one project, it builds a `HudReports::ReportInstance` and runs the APR (or the CE APR for the CE tab). A type with no projects gets no sub-report, no tab and no summary row.
3. Each APR receives only the selected projects of its type. The CE APR receives every selected project, whatever its type, so narrowing the selection narrows CE too.
4. `CellSnapshot` copies the cells the row definitions name into `simple_report_cells`. A re-run deletes the report's previous cells first.

Sub-reports run as the requesting user, not `User.system_user`. The user owns them and their project visibility and PII policy apply. Projects the user can't see are excluded.

Sub-reports are given explicit project ids and nothing else. The generator rebuilds its filter from the sub-report's options, so passing project types, organizations, data sources or project groups would add projects back.

`SubReportRunner` raises `CocUnavailable` before running anything if the rebuilt filter no longer holds exactly the stored CoC. `Filter#update` silently drops a CoC the user can no longer use (access changed, CoC deactivated, a saved filter run later), and without the check the sub-reports would cover every CoC the user can see.

## Row definitions

The rows each report shows live in `drivers/continuum_semi_annual_performance/config/rows.yml`, loaded once at boot into `RowDefinitions::DATA`. Other reports that read HUD sub-report cells call `answer(report, table, cell)` in Ruby, but these reports define about 340 rows across four project types, each type orders them differently, and product checks them line by line against a spec they own, so the rows are kept as data. Use this approach for a new report with a long, spec-driven list of sub-report cells, and the Ruby approach for a report with a few computed metrics.

The file has three sections: `mid_year`, `end_of_year` and `end_of_year_ce`. Each entry has:

| Key | Meaning |
|---|---|
| `label` | Text shown to the user |
| `order` | Position per project type, such as `es: 4`. A row appears only for the types listed |
| `header`, `level` | A heading row. `level: 1` is a question heading, `level: 2` a sub-heading under it |
| `op` | `value` (one cell), `sum` (several cells) or `sum_range` (two cells naming the ends of a column range) |
| `cells` | `report` (`apr` or `ce_apr`), `table` and `cell` |
| `format` | `count`, `percent` or `decimal` |
| `source` | A plain-language description of the cells, such as `APR Table Q6f - Cell C2`. Copied into each snapshot row and shown in the Source column on the page and in the exports |

`rows_yaml_shape_spec.rb` checks the shape: allowed keys, positive unique positions per type, valid ops and formats, one cell for `value`, and the right report for each section. A malformed edit fails that spec rather than a report run.

`RowDefinitions.questions` derives the question list each sub-report is built with, from the tables its rows use. Questions 7 and 8 are always built because the summary tab reads them (Q7a B6 persons served, Q8a B2 households served).

Values are snapshotted, not read at render time. A cell the generator never wrote counts as `0`.

### Totals that don't use the table's Total row

Some totals add specific cells instead of reading the APR table's own Total row:

- Q11 Age Total, Q12 Total and Q15 Living Situation Total sum the listed rows of their column.
- "Total Number of Veterans" is Q25a B2 + B3. The table's Total row (B7) also counts non-veterans.
- "Total Chronically Homeless Persons by Household" is Q26b C2 + D2: households without children plus households with adults and children. Households with only children (column E) and unknown household type (column F) are not included, so the value can be lower than Q26b B2.

## Drill-down links

Each value links to the matching cell of its HUD sub-report. `ReportsHelper#drilldown_visible?` shows the link only when the viewer could open that page, mirroring the checks `HudReports::BaseController` makes:

- the viewer can view reports and has the APR report definition (for `apr` cells) or the CE APR report definition (for `ce_apr` cells), and
- the sub-report is in `HudReports::ReportInstance.viewable_by` for the viewer (they own it or have `can_view_all_hud_reports`), the same scope the HUD controller uses to load it, and
- the sub-report exists and has not been purged.

Otherwise the value shows without a link. `HudApr::DrilldownPresenter` applies the viewer's PII policy once the link is followed.

## Access and exports

Access follows the standard warehouse report rules in [reports-framework.md](reports-framework.md#registration-and-per-user-access): the report definition must be assigned to the user, and `SimpleReports::ReportInstance.viewable_by` decides whose runs a user sees. The controllers are V2 controllers: they use `authorize_with` (`can_view_any_reports?` plus the report definition) instead of including `WarehouseReportAuthorization`.

A report that is not `completed?` shows a "Report Running" or "Report Failed" page with no values, and approval and exports are refused until it completes.

Excel and PDF downloads use the `DocumentExport` pipeline described in [reports-framework.md](reports-framework.md#document-exports) and [document-export.md](document-export.md), one tab or the whole report per download.

## Approval

Anyone who can view a completed report can approve or unapprove it. Each change of state inserts a `ContinuumSemiAnnualPerformance::Approval` row; a save that leaves the state unchanged writes nothing. The newest row is the current state, and the page lists the history. Approval has no other effect: no locking, visibility change or notification.

## Archival

Both reports archive like other `SimpleReports` reports; see [reports-framework.md](reports-framework.md#archival). The driver initializer `continuum_semi_annual_performance_archival.rb` loads both subclasses at boot so their types are registered and included in base-class queries.

The linked HUD sub-reports are archived and purged on their own schedule. Once a sub-report is purged its drill-down links disappear and the snapshotted values still show.

Deleting a report soft-deletes it; its HUD sub-reports stay in place.

## Related

- [hud-report-framework.md](hud-report-framework.md): the APR and CE APR generators the sub-reports run.
- [reports-framework.md](reports-framework.md): report registration, access, document exports and archival.
- [document-export.md](document-export.md): how `DocumentExport` jobs and downloads work.
