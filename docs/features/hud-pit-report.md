# HUD PIT Report

The HUD Point-in-Time (PIT) Report provides a snapshot of homelessness on a single night. It aggregates data for sheltered and unsheltered individuals across various project types.

## Architecture

The PIT report follows the [HUD Report Framework](hud-report-framework.md) but uses a "Lazy Shared Universe" pattern for data processing.

### Core Components

- **Generator**: `HudPit::Generators::Pit::Fy2025::Generator` orchestrates the report execution.
- **Snapshot Model**: `HudPit::Fy2025::PitClient` caches calculated client-level data (age, race, chronic status, etc.) for the specific PIT date.
- **Base Question**: `HudPit::Generators::Pit::Fy2025::Base` contains the logic for populating the `PitClient` snapshot and shared calculation methods.
- **Questions**: Individual classes (e.g., `AdultAndChild`, `Adults`, `Children`) define specific report sections, their row labels, and project type filters.

### Data Processing Pipeline

1.  **Initialization**: The report is initialized with a specific date (`on`), CoC codes, and project filters.
2.  **Universe Population (Lazy)**: The first question that runs triggers the `add` method in `HudPit::Generators::Pit::Fy2025::Base`.
    - It identifies all clients in residential projects on the PIT date.
    - It filters out clients with a Permanent Housing (PH) move-in date on or before the PIT date.
    - It calculates derived attributes (e.g., `chronically_homeless`, `pit_race`, `household_type`).
    - It saves these records to the `hud_pit_pit_clients` table (via `PitClient`).
3.  **Question Execution**: Each question filters the shared `PitClient` universe (using `filter_pending_associations`) and aggregates data into report cells.
4.  **Aggregation**: Results are stored in `HudReports::ReportCell` and linked to `PitClient` records via `HudReports::UniverseMember`.

## Key Logic

### PIT Race Calculation
The report uses a specific race vocabulary defined by HUD for PIT. This is implemented in `HudPit::Fy2025::PitClient.pit_race`. It handles combinations of races and Hispanic/Latina/e/o ethnicity differently than standard HUD reports.

### Household Composition
Household types (e.g., `adults_and_children`, `adults_only`, `children_only`) are calculated based on the members present in the household on the PIT date.

### Project Types
The report includes the following project types:
- **Emergency Shelter (ES)**: Codes 0, 1
- **Transitional Housing (TH)**: Code 2
- **Safe Haven (SH)**: Code 8
- **Street Outreach (SO)**: Code 4

## Entry Points

- **Generator**: `drivers/hud_pit/app/models/hud_pit/generators/pit/fy2025/generator.rb`
- **Controller Concern**: `drivers/hud_pit/app/controllers/hud_pit/pit_concern.rb`

## Related Documentation

- [HUD Report Framework](hud-report-framework.md)
- [HUD Utility 2024](../../lib/util/hud_utility_2024.rb) (Used for race and project type definitions)
