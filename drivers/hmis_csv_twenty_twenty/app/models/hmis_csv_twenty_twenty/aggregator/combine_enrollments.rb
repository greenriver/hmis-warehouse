###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HmisCsvTwentyTwenty::Aggregator
  class CombineEnrollments
    INSERT_BATCH_SIZE = 2_000

    def self.aggregate!(importer_id)
      project_ids = project_source.where(combine_enrollments: true).pluck(:ProjectID)
      batch = []
      enrollment_source.where(importer_log_id: importer_id).find_each do |enrollment|
        if project_ids.include?(enrollment.ProjectID)
          # This enrollment is in a project that needs to be combined
        else
          # Pass the enrollment through for ingestion
          destination = new_from(enrollment)
          destination.importer_log_id = importer_id
          destination.aggregated_at = Time.current
          destination.set_source_hash
          batch << destination
        end

        if batch.count >= INSERT_BATCH_SIZE
          enrollment_destination.import(batch)
          batch = []
        end
      end
      enrollment_destination.import(batch) if batch.present?
    end

    def self.new_from(source)
      source_data = source.slice(enrollment_source.hmis_structure(version: '2020').keys)
      enrollment_destination.new(source_data.merge(source_type: source.class.name, source_id: source.id, data_source_id: source.data_source_id))
    end

    def self.project_source
      GrdaWarehouse::Hud::Project
    end

    def self.enrollment_source
      HmisCsvTwentyTwenty::Importer::Enrollment
    end

    def self.enrollment_destination
      HmisCsvTwentyTwenty::Aggregator::Enrollment
    end
  end
end
