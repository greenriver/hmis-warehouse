# frozen_string_literal: true

module HudReports
  # Represents a "Logic Snapshot" for a specific report instance.
  #
  # ## Role & Responsibility
  # This model stores pre-computed, household-level business logic that is shared across
  # multiple HUD reports. It sits between the global Service History (raw data) and
  # report-specific snapshots like AprClient or SpmEnrollment.
  #
  # Its primary goal is to resolve complex inheritance and composition rules once per report run,
  # allowing Question classes to use simple SQL joins instead of expensive Ruby runtime loops. The
  # context records maybe shared between reports and sub-reports, for example the SPM uses APR DQ
  # reports internally, both reports can share these records to avoid duplicate or work and
  # inconsistent results.
  #
  # ## Lifecycle
  # - Ephemeral: Records are created during the 'Preparation' phase of a report job.
  # - Idempotent: Cleared and rebuilt if a report is retried.
  # - Scoped: Always tied to a specific `ReportInstance`
  class HouseholdContext < GrdaWarehouseBase
    self.table_name = 'hud_report_household_contexts'

    belongs_to :report_instance, class_name: 'HudReports::ReportInstance'
    belongs_to :service_history_enrollment, class_name: 'GrdaWarehouse::ServiceHistoryEnrollment'

    def self.prune!
      # Delete contexts for reports older than 2 weeks or reports where the report instance no longer exists
      old_report_ids = HudReports::ReportInstance.where(created_at: ..2.weeks.ago).select(:id)
      where(report_instance_id: old_report_ids).
        or(where.not(report_instance_id: HudReports::ReportInstance.select(:id))).
        delete_all
    end

    # Efficiently copies contexts from a source report for a specific set of enrollments
    # Used when sharing logic between reports (e.g. SPM -> DQ)
    # NOTE: this could be done more efficiently in SQL, room for future optimization
    def self.copy_subset!(source_report_id:, target_report_id:, service_history_enrollment_ids:)
      source_contexts = where(
        report_instance_id: source_report_id,
        service_history_enrollment_id: service_history_enrollment_ids,
      )

      source_contexts.find_in_batches(batch_size: 1000) do |batch|
        new_contexts = batch.map do |ctx|
          ctx.dup.tap { |new_ctx| new_ctx.report_instance_id = target_report_id }
        end
        import!(new_contexts)
      end
    end

    # Returns a hash compatible with the legacy hash-based household logic.
    # Used to pass pre-computed context into older logic modules (e.g. HudReports::Households)
    # that expect a hash representation of a member rather than a database record.
    def to_legacy_member_hash
      {
        client_id: destination_client_id,
        source_client_id: source_client_id,
        dob: dob,
        age: age,
        veteran_status: veteran_status,
        pit_chronic_status: raw_pit_chronic_status,
        pit_chronic_detail: raw_pit_chronic_detail,
        chronic_status: raw_chronic_status,
        chronic_detail: raw_chronic_detail,
        relationship_to_hoh: relationship_to_hoh,
        entry_date: member_entry_date,
        exit_date: member_exit_date,
        move_in_date: inherited_move_in_date,
        effective_move_in_date: inherited_move_in_date,
      }.with_indifferent_access
    end
  end
end
