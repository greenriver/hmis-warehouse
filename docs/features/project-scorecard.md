# Project Scorecard

The Project Scorecard is a warehouse report that evaluates HMIS projects and project groups across four scored categories. It auto-populates metrics from HUD APR and SPM report runs, then enters a multi-step review workflow with email notifications before finalization.

**Driver:** `drivers/project_scorecard`

## Entry Points

- **Controller:** `ProjectScorecard::WarehouseReports::ScorecardsController`
- **Model:** `ProjectScorecard::Report` (table: `project_scorecard_reports`, warehouse DB)
- **Job:** `WarehouseReports::GenericReportJob` dispatches report generation
- **Routes:** Nested under `project_scorecard/warehouse_reports/scorecards`

## Report Lifecycle

A report moves through four statuses:

```
pending → pre-filled → ready → completed
```

1. **pending** — Created and queued for background processing.
2. **pre-filled** — Metrics populated from APR, SPM, and HMIS data. The report creator reviews and edits values.
3. **ready** — Sent to project/organization contacts for agency response.
4. **completed** — An HTML archive snapshot is stored and the creator is notified.

The `complete` and `rewind` member routes advance or reverse the workflow.

## Scoring

`TotalScore` computes a weighted percentage from four category scores, each implemented as a concern on `Report`:

| Category | Concern Module |
|---|---|
| Project Performance | `ProjectPerformance` |
| Data Quality | `DataQuality` |
| CE Participation | `CeParticipation` |
| Grant Management & Financials | `GrantManagementAndFinancials` |

`ReviewOnly` (site monitoring, CES rejected referrals, VI-SPDAT) displays in the UI but does not contribute to the total.

## Data Sources

Report generation auto-populates from three sources:

- **HUD APR** — utilization, exits to permanent housing, income changes, data quality error rates. Requires the `:hud_apr` driver.
- **HUD SPM** Measure 2 — returns to homelessness. Requires the `:hud_spm_report` driver.
- **HMIS VI-SPDAT** — client count and average score via `GrdaWarehouse::HmisForm`.

Remaining fields (financials, PIT participation, CoC meetings, etc.) are entered manually.

## Associations

- `belongs_to :project` (`GrdaWarehouse::Hud::Project`, optional)
- `belongs_to :project_group` (`GrdaWarehouse::ProjectGroup`, optional)
- `belongs_to :user` (report creator)
- `belongs_to :apr` / `belongs_to :spm` (`HudReports::ReportInstance`, optional)
- Contacts resolved through project and project group associations

## Field Locking

`Report#locked?` restricts which fields are editable based on the current status. The creator edits scored fields during `pre-filled`; contacts edit agency response fields during `ready`; all fields lock on `completed`.

## PDF Export

`ProjectScorecard::DocumentExports::ScorecardExport` renders a PDF via the `performance_report` layout.

## Email Notifications

`ProjectScorecard::ScorecardMailer` sends notifications at each workflow transition: after pre-fill, when sent to contacts, and on completion.

## Related

- `boston_project_scorecard` driver — a variant with a parallel structure
