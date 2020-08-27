###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HmisCsvTwentyTwenty::Aggregated
  class FilterExits
    INSERT_BATCH_SIZE = 2_000

    def self.aggregate!(importer_log)
      project_ids = project_source.
        where(combine_enrollments: true, data_source_id: importer_log.data_source_id).
        pluck(:ProjectID)

      batch = []
      exit_source.where(importer_log_id: importer_log.id).find_each do |enrollment_exit|
        # Pass the exits through for ingestion for the projects that don't combine enrollments
        # The projects that combine enrollments emit exits during enrollment processing
        batch << new_from(enrollment_exit, importer_log) unless project_ids.include?(enrollment_exit.enrollment.ProjectID)

        if batch.count >= INSERT_BATCH_SIZE
          # These are imported into the staging table, there is no uniqueness constraint, and no existing data
          # thus no need to check conflict targets
          exit_destination.import(batch)
          batch = []
        end
      end
      return unless batch.present?

      # These are imported into the staging table, there is no uniqueness constraint, and no existing data
      # thus no need to check conflict targets
      exit_destination.import(batch)
    end

    def self.new_from(source, importer_log)
      source_data = source.slice(exit_source.hmis_structure(version: '2020').keys)
      new_exit = exit_destination.new(
        source_data.merge(
          source_type: source.class.name,
          source_id: source.id,
          data_source_id: source.data_source_id,
          importer_log_id: importer_log.id,
          pre_processed_at: Time.current,
        ),
      )
      new_exit.set_source_hash

      new_exit
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
