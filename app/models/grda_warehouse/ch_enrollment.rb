###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  class ChEnrollment < GrdaWarehouseBase
    include ArelHelper
    belongs_to :enrollment, class_name: 'GrdaWarehouse::Hud::Enrollment'

    scope :detached, -> do
      where.not(enrollment_id: GrdaWarehouse::Hud::Enrollment.select(:id))
    end

    scope :needs_processing, -> do
      joins(:enrollment).where(arel_table[:processed_as].not_eq(e_t[:processed_as]))
    end

    scope :chronically_homeless, -> do
      where(chronically_homeless_at_entry: true)
    end

    def self.maintain!
      # remove any where the enrollment is no longer in the system
      detached.destroy_all
      add_new!
      update_existing!
    end

    def self.add_new!
      GrdaWarehouse::Hud::Enrollment.processed.
        preload(:project).
        where.not(id: all.select(:enrollment_id)).find_in_batches do |enrollments|
          batch = []
          enrollments.each do |enrollment|
            batch << {
              enrollment_id: enrollment.id,
              processed_as: enrollment.processed_as,
              chronically_homeless_at_entry: enrollment.chronically_homeless_at_start?,
            }
          end
          import(batch)
        end
    end

    def self.update_existing!
      needs_processing.preload(enrollment: :project).find_in_batches do |ch_enrollments|
        batch = []
        ch_enrollments.each do |ch_enrollment|
          enrollment = ch_enrollment.enrollment
          batch << {
            id: ch_enrollment.id,
            processed_as: enrollment.processed_as,
            chronically_homeless_at_entry: enrollment.chronically_homeless_at_start?,
          }
        end
        import(
          batch,
          on_duplicate_key_update: {
            conflict_target: [:id],
            columns: [:processed_as, :chronically_homeless_at_entry],
          },
        )
      end
    end
  end
end
