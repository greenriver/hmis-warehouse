## HUD System Performance Measures (SPM)

### Introduction
- For HUD’s official specification, see https://www.hudexchange.info/resource/4483/system-performance-measures-tools/.
- Legacy generators for FY2020, FY2023, and FY2024 remain in the driver for backward compatibility, but FY2026 is the active implementation.
- `HudSpmReport.current_generator` switches between FY2026 and FY2024 based on the configured default report version.

### Architecture
- The SPM feature ships as a Rails driver under `drivers/hud_spm_report`. Controllers inherit from the shared HUD reports controller stack and mount under the `/hud_reports/spms` namespace.
- The FY2026 generator exposes metadata (title, question list, filter class, upload capabilities) to the HUD reports framework. Each question maps to a dedicated measure class that encapsulates table preparation and summary calculation logic.
- `Generator.questions` returns the ordered measure list (Measures 1–7 plus HDX upload). HUD report answers reference these classes via the question number.

### Key Classes
- **SpmEnrollment**: Denormalized enrollment records that capture client identity, age, project, destination, income history, homelessness status, and funding eligibility. These records back most measure universes and expose scopes for active method definitions and literal homelessness checks.
- **Episode**: Derived time-series representation of homeless episodes built from enrollment bed nights. It uses `EpisodeBatch` to compute contiguous timelines and stores summary statistics (first date, last date, total days).
- **EpisodeBatch**: Builds contiguous homelessness episodes, merging bed-night data, self-reported start dates, and PH adjustments before persisting `Episode` rows.
- **Return**: Represents returns to homelessness after a permanent exit, combining the exit enrollment with a potential return enrollment to compute days-to-return and destination classifications.
- **ServiceHistoryEnrollmentFilter**: Applies HUD filter options and guarantees only SPM-relevant projects feed the denormalization step.

### Calculation Flow
- **Filtering**: `ServiceHistoryEnrollmentFilter` adapts the general HUD filter form to SPM-specific project types. It queries `ServiceHistoryEnrollment`, applies CoC and project filters, and returns the `Hud::Enrollment` rows needed for denormalization.
- **Enrollment set**: `SpmEnrollment.create_enrollment_set` uses the adapter to load enrollments, augments them with household context, income history, and eligibility data, and bulk imports into the SPM enrollment table. The method batches work to avoid loading entire universes in memory.
- **Measure execution**: Each measure inherits from `MeasureBase`, which ensures the enrollment set exists, prepares table metadata, and provides helper methods such as `percent`. Measures create universes, add members, and update HUD report answers with counts or derived statistics.
- **Episodes and returns**: Measure 1 builds `Episode` records through `EpisodeBatch`, while Measure 2 uses `Return.compute_returns` to pair exits with subsequent enrollments and calculate days to return.
- **Answer persistence**: Measures add members to HUD report universes and update cell summaries. Additional detail exports (e.g., drill-down CSV) use the shared `Detail` concern to populate header metadata.

### Seven Measures (FY2026)
- **Measure 1** (`MeasureOne`): Calculates days homeless for ES/SH/TH/PH households using episode timelines, producing average and median values for universes 1a and 1b.
- **Measure 2** (`MeasureTwo`): Counts returns to homelessness after exits to permanent housing, broken into 0–180, 181–365, and 366–730 day windows across project types.
- **Measure 3** (`MeasureThree`): Aggregates annualized counts of persons experiencing homelessness, primarily using `SpmEnrollment` scope data.
- **Measure 4** (`MeasureFour`): Tracks income growth for adult stayers and leavers, comparing current and prior income snapshots attached to each enrollment.
- **Measure 5** (`MeasureFive`): Identifies first-time homelessness by checking prior enrollments during the two-year lookback window.
- **Measure 6** (`MeasureSix`): Measures successful placements and returns for TH/SH projects (part a/b) and Category 3 homelessness (part c).
- **Measure 7** (`MeasureSeven`): Evaluates exits to permanent housing for Street Outreach and mixed project types, and retention for RRH/PH move-ins.
- **HDX Upload**: Generates the HDX 2.0 CSV submission by mapping SPM cell values to HDX columns through strongly typed metadata definitions.
