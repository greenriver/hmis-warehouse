# frozen_string_literal: true

module HudReports
  # Represents a "Logic Snapshot" for a specific report instance.
  #
  # ## Role & Responsibility
  # This model stores pre-computed, household-level business logic that is shared across
  # multiple HUD reports. It sits between the global Service History (raw data) and
  # report-specific snapshots like AprClient (presentation data).
  #
  # Its primary goal is to resolve complex inheritance and composition rules once per report run,
  # allowing Question classes to use simple SQL joins instead of expensive Ruby runtime loops.
  #
  # ## Key Attributes
  # - Chronic Status Inheritance: Resolves if a member is chronic based on HoH or other adults.
  # - Move-in Date Inheritance: Derives move-in dates when missing based on HoH and entry dates.
  # - Household Composition: Categorizes the household (e.g., adults_only, children_only).
  #
  # ## Lifecycle
  # - Ephemeral: Records are created during the 'Preparation' phase of a report job.
  # - Idempotent: Cleared and rebuilt if a report is retried.
  # - Scoped: Always tied to a specific `ReportInstance`
  class HouseholdContext < GrdaWarehouseBase
    self.table_name = 'hud_report_household_contexts'

    belongs_to :report_instance, class_name: 'HudReports::ReportInstance'
    belongs_to :service_history_enrollment, class_name: 'GrdaWarehouse::ServiceHistoryEnrollment'
  end
end
