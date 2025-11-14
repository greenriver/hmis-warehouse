## HUD System Performance Measures (SPM)

### Introduction
- For HUD’s official specification, see https://www.hudexchange.info/resource/4483/system-performance-measures-tools/.
- Legacy generators for FY2020, FY2023, and FY2024 remain in the driver for backward compatibility, but FY2026 is the active implementation.
- `HudSpmReport.current_generator` switches between FY2026 and FY2024 based on the configured default report version.

### Architecture
- The SPM feature ships as a Rails driver under `drivers/hud_spm_report`. Controllers inherit from the shared HUD reports controller stack and mount under the `/hud_reports/spms` namespace.
- The FY2026 generator exposes metadata (title, question list, filter class, upload capabilities) to the HUD reports framework. Each question maps to a dedicated measure class that encapsulates table preparation and summary calculation logic.
- `Generator.questions` returns the ordered measure list (Measures 1–7 plus HDX upload). HUD report answers reference these classes via the question number.

```9:45:drivers/hud_spm_report/app/models/hud_spm_report/generators/fy2026/generator.rb
module HudSpmReport::Generators::Fy2026
  class Generator < ::HudReports::GeneratorBase
    # ...
    def self.questions
      [
        HudSpmReport::Generators::Fy2026::MeasureOne,
        HudSpmReport::Generators::Fy2026::MeasureTwo,
        HudSpmReport::Generators::Fy2026::MeasureThree,
        HudSpmReport::Generators::Fy2026::MeasureFour,
        HudSpmReport::Generators::Fy2026::MeasureFive,
        HudSpmReport::Generators::Fy2026::MeasureSix,
        HudSpmReport::Generators::Fy2026::MeasureSeven,
        HudSpmReport::Generators::Fy2026::HdxUpload,
      ].map do |q|
        [q.question_number, q]
      end.to_h.freeze
    end
  end
end
```

### Data Models
- **SpmEnrollment**: Denormalized enrollment records that capture client identity, age, project, destination, income history, homelessness status, and funding eligibility. These records back most measure universes and expose scopes for active method definitions and literal homelessness checks.
- **Episode**: Derived time-series representation of homeless episodes built from enrollment bed nights. It uses `EpisodeBatch` to compute contiguous timelines and stores summary statistics (first date, last date, total days).
- **Return**: Represents returns to homelessness after a permanent exit, combining the exit enrollment with a potential return enrollment to compute days-to-return and destination classifications.

```9:35:drivers/hud_spm_report/app/models/hud_spm_report/fy2026/spm_enrollment.rb
module HudSpmReport::Fy2026
  class SpmEnrollment < HudReports::ReportClientBase
    self.table_name = 'hud_report_spm_enrollments'
    include ArelHelper
    include Detail
    # ...
    belongs_to :report_instance, class_name: 'HudReports::ReportInstance'
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client'
    belongs_to :enrollment, class_name: 'GrdaWarehouse::Hud::Enrollment'
    has_many :episodes, through: :enrollment_links
    # ...
  end
end
```

```9:44:drivers/hud_spm_report/app/models/hud_spm_report/fy2026/episode.rb
module HudSpmReport::Fy2026
  class Episode < HudReports::ReportClientBase
    self.table_name = 'hud_report_spm_episodes'
    include Detail
    has_many :enrollments, through: :enrollment_links
    has_many :bed_nights
    # ...
  end
end
```

```9:44:drivers/hud_spm_report/app/models/hud_spm_report/fy2026/return.rb
module HudSpmReport::Fy2026
  class Return < HudReports::ReportClientBase
    self.table_name = 'hud_report_spm_returns'
    include Detail
    belongs_to :exit_enrollment, class_name: 'HudSpmReport::Fy2026::SpmEnrollment'
    belongs_to :return_enrollment, class_name: 'HudSpmReport::Fy2026::SpmEnrollment', optional: true
    # ...
  end
end
```

### Calculation Flow
- **Filtering**: `ServiceHistoryEnrollmentFilter` adapts the general HUD filter form to SPM-specific project types. It queries `ServiceHistoryEnrollment`, applies CoC and project filters, and returns the `Hud::Enrollment` rows needed for denormalization.

```19:39:drivers/hud_spm_report/app/models/hud_spm_report/adapters/service_history_enrollment_filter.rb
module HudSpmReport::Adapters
  class ServiceHistoryEnrollmentFilter
    def initialize(report_instance)
      spm_project_types = HudHelper.util.spm_project_type_numbers
      @filter = Filters::HudFilterBase.new(user_id: report_instance.user.id, relevant_project_types: spm_project_types).update(report_instance.options)
      @project_ids = GrdaWarehouse::Hud::Project.where(ProjectType: spm_project_types, id: report_instance.project_ids).pluck(:id)
    end
    # ...
  end
end
```

- **Enrollment set**: `SpmEnrollment.create_enrollment_set` uses the adapter to load enrollments, augments them with household context, income history, and eligibility data, and bulk imports into the SPM enrollment table. The method batches work to avoid loading entire universes in memory.

```139:198:drivers/hud_spm_report/app/models/hud_spm_report/fy2026/spm_enrollment.rb
// ... existing code ...
def self.create_enrollment_set(report_instance)
  filter = ::Filters::HudFilterBase.new(user_id: report_instance.user.id).update(report_instance.options)
  enrollments = HudSpmReport::Adapters::ServiceHistoryEnrollmentFilter.new(report_instance).enrollments
  household_infos = household(enrollments)
  enrollments.preload(:client, :destination_client, :exit, :income_benefits_at_exit, :income_benefits_at_entry, :income_benefits, project: :funders).find_in_batches(batch_size: 500) do |batch|
    members = []
    batch.each do |enrollment|
      # ...
      members << {
        report_instance_id: report_instance.id,
        client_id: enrollment.destination_client.id,
        enrollment_id: enrollment.id,
        # denormalized income and homelessness fields
      }
    end
    import!(members)
  end
end
// ... existing code ...
```

- **Measure execution**: Each measure inherits from `MeasureBase`, which ensures the enrollment set exists, prepares table metadata, and provides helper methods such as `percent`. Measures create universes, add members, and update HUD report answers with counts or derived statistics.

```9:69:drivers/hud_spm_report/app/models/hud_spm_report/generators/fy2026/measure_base.rb
module HudSpmReport::Generators::Fy2026
  class MeasureBase < ::HudReports::QuestionBase
    def self.client_class
      HudSpmReport::Fy2026::SpmEnrollment
    end
    # ...
    private def enrollment_set
      enrollments = @report.spm_enrollments
      return enrollments if enrollments.exists?
      HudSpmReport::Fy2026::SpmEnrollment.create_enrollment_set(@report)
      @report.spm_enrollments
    end
    # ...
  end
end
```

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

### Key Components
- **ServiceHistoryEnrollmentFilter**: Applies HUD filter options and guarantees only SPM-relevant projects feed the denormalization step.
- **EpisodeBatch**: Builds contiguous homelessness episodes, merging bed-night data, self-reported start dates, and PH adjustments before persisting `Episode` rows.
- **Detail concern**: Provides shared column header mappings and PII handling for drill-down exports across `SpmEnrollment`, `Episode`, and `Return`.
- **HDX Upload**: Generates the HDX 2.0 CSV submission by mapping SPM cell values to HDX columns through strongly typed metadata definitions.

```9:200:drivers/hud_spm_report/app/models/hud_spm_report/generators/fy2026/hdx_upload.rb
// ... existing code ...
class HdxUpload < MeasureBase
  def run_question!
    tables = [
      ['csv', :run_csv],
    ]
    @report.start(self.class.question_number, tables.map(&:first))
    tables.each do |name, msg|
      send(msg, name)
    end
    @report.complete(self.class.question_number)
  end
  # COLUMNS constant maps HDX variable names to SPM cells
end
// ... existing code ...
```

### Controllers and Views
- `HudSpmReport::SpmsController` handles report creation, queuing, history pages, and running status updates via HUD report endpoints.
- `HudSpmReport::MeasuresController` wraps individual measure pages, defaulting the filter to FY2026 project types and routing to `/hud_reports/spms/:spm_id/measures/:id`.
- Drill-down endpoints (`HudSpmReport::CellsController`) render detail tables or export CSV/XLSX using the HUD reports answer metadata populated by the measure classes.

```9:40:drivers/hud_spm_report/app/controllers/hud_spm_report/measures_controller.rb
module HudSpmReport
  class MeasuresController < BaseController
    before_action :set_report, only: [:show, :destroy, :running, :result]
    before_action :set_question
    # ...
    def create
      question = params[:question]
      @report = report_source.from_filter(@filter, report_name, build_for_questions: [question])
      generator.new(@report).queue
      redirect_to path_for_history
    end
  end
end
```

### Operational Notes
- All measure execution occurs through Delayed Job when queued from the UI; `Generator#queue` schedules the report and the framework updates HUD report status fields.
- FY2026 data tables live in the warehouse database (`hud_report_spm_enrollments`, `hud_report_spm_episodes`, `hud_report_spm_returns`). Ensure migrations run against the warehouse schema before enabling the driver in a new environment.
- Publish and detail exports rely on the shared HUD reports publishing pipeline (`HudReports::ReportInstance`), so any downstream customization should be implemented through driver-specific detail templates rather than modifying measure logic.
