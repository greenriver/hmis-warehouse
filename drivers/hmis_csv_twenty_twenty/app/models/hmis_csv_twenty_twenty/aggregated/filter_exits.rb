###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HmisCsvTwentyTwenty::Aggregated
  class FilterExits
    INSERT_BATCH_SIZE = 2_000

    def self.aggregate!(importer_id)
      project_ids = project_source.where(combine_enrollments: true).pluck(:ProjectID)
      batch = []
      exit_source.where(importer_log_id: importer_id).find_each do |enrollment_exit|
        # Exits for the projects that combine enrollments are handled in the enrollment processing
        unless project_ids.include?(enrollment_exit.enrollment.ProjectID)
          # Pass the exit through for ingestion
          destination = new_from(enrollment_exit)
          destination.importer_log_id = importer_id
          destination.pre_processed_at = Time.current
          destination.set_source_hash
          batch << destination
        end

        if batch.count >= INSERT_BATCH_SIZE
          exit_destination.import(batch)
          batch = []
        end
      end
      exit_destination.import(batch) if batch.present?
    end

    def self.new_from(source)
      source_data = source.slice(exit_source.hmis_structure(version: '2020').keys)
      exit_destination.new(source_data.merge(source_type: source.class.name, source_id: source.id, data_source_id: source.data_source_id))
    end

    def self.project_source
      GrdaWarehouse::Hud::Project
    end

    def self.exit_source
      HmisCsvTwentyTwenty::Aggregated::Exit.
        preload(:enrollment)
    end

    def self.exit_destination
      HmisCsvTwentyTwenty::Importer::Exit
    end
  end
end
