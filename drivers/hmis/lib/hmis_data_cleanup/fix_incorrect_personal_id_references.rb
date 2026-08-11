###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Align enrollment-related records' PersonalID to the PersonalID on the Enrollment they reference.
module HmisDataCleanup
  class FixIncorrectPersonalIdReferences
    # @param data_source_id [Integer] The data source to operate on.
    # @param enrollment_ids [Array<Integer>, nil] Optional HUD EnrollmentIds to limit the fix to.
    # @param project_ids [Array<String>, nil] Optional HUD ProjectIDs to limit the fix to.
    # @param classes [Array<Class>, nil] Optional array of classes to process. If nil, processes all enrollment-related classes.
    # @param dry_run [Boolean] If true, only reports what would be fixed without making changes.
    # @raise [ArgumentError] If both enrollment_ids and project_ids are provided.
    def self.run!(data_source_id:, enrollment_ids: nil, project_ids: nil, classes: nil, dry_run: false)
      classes&.each do |klass|
        raise "Invalid class: #{klass.name}" unless Hmis::Hud::Enrollment.hmis_enrollment_related_classes.include?(klass)
      end

      classes ||= Hmis::Hud::Enrollment.hmis_enrollment_related_classes

      raise ArgumentError, 'Pass enrollment_ids or project_ids, but not both' if enrollment_ids.present? && project_ids.present?

      enrollment_scope = GrdaWarehouse::Hud::Enrollment.where(data_source_id: data_source_id)
      enrollment_scope = enrollment_scope.where(EnrollmentID: enrollment_ids) if enrollment_ids.present?
      enrollment_scope = enrollment_scope.where(ProjectID: project_ids) if project_ids.present?

      Hmis::Hud::Base.transaction do
        classes.each do |klass|
          # Build the base scope for records
          base_scope = klass.where(data_source_id: data_source_id)
          base_scope = base_scope.where(EnrollmentID: enrollment_scope.select(:EnrollmentID))

          # Outer join to enrollment and select records where the enrollment is null,
          # indicating the record's PersonalID may be incorrect (the EnrollmentID and
          # PersonalID columns don't point to the same enrollment).
          records_needing_update = base_scope.
            left_outer_joins(:enrollment).
            where(GrdaWarehouse::Hud::Enrollment.arel_table[:id].eq(nil))

          ids = records_needing_update.limit(15).pluck(:id)
          num_records = records_needing_update.count
          Rails.logger.info "[#{klass.name}] Found #{num_records} records with potentially bad PersonalID: #{ids.inspect}#{'...' if num_records > 15}"

          next if dry_run

          records_needing_update.find_in_batches do |batch|
            Rails.logger.info "[#{klass.name}] Processing batch"

            # map {EnrollmentID=>PersonalID} for each enrollment referenced by this batch of records
            eid_to_pid = enrollment_scope.where(EnrollmentID: batch.map(&:EnrollmentID)).
              pluck(:EnrollmentID, :PersonalID).to_h

            values = []
            batch.each do |record|
              real_personal_id = eid_to_pid[record.EnrollmentID]
              next unless real_personal_id # enrollment not found, so we cant update the PersonalID
              next if record.PersonalID == real_personal_id # this shouldn't be true, but check anyway

              record.PersonalID = real_personal_id
              values << record
            end

            if values.any?
              Rails.logger.info "[#{klass.name}] change batch: #{values.map { |r| [r.id, r.PersonalID_was, r.PersonalID] }.inspect}"
              result = klass.import(
                values,
                validate: false,
                timestamps: false,
                on_duplicate_key_update: { conflict_target: [:id], columns: [:PersonalID] },
              )

              raise "Failed: #{result.failed_instances}" if result.failed_instances.present?

              Rails.logger.info "[#{klass.name}] updated #{result.ids.count} records"
            end
          end
        end
      end

      if dry_run
        Rails.logger.info 'Dry run complete'
      else
        Rails.logger.info 'Finished fixing incorrect PersonalID references'
      end
    end
  end
end
