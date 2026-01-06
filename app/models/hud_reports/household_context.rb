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
  # - PIT Chronic Status Inheritance: Resolves if a member is chronic on PIT date based on HoH or other adults.
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

    def to_legacy_member_hash
      {
        client_id: destination_client_id,
        source_client_id: source_client_id,
        dob: dob,
        age: age,
        veteran_status: veteran_status,
        pit_chronic_status: pit_chronic_status,
        chronic_status: inherited_chronic_status,
        chronic_detail: inherited_chronic_detail,
        relationship_to_hoh: relationship_to_hoh,
        entry_date: hoh_entry_date,
        exit_date: hoh_exit_date,
        move_in_date: inherited_move_in_date,
      }.with_indifferent_access
    end
  end
end
