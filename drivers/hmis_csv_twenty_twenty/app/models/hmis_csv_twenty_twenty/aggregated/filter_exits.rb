###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HmisCsvTwentyTwenty::Aggregated
  class FilterExits
    INSERT_BATCH_SIZE = 2_000

    def self.aggregate!(importer_log)
    end

    def self.remove_deleted_overlapping_data!(importer_log:, date_range:)
    end

    def self.copy_incoming_data!(importer_log:)
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
