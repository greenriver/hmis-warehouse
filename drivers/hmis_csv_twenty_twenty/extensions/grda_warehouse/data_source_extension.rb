###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwenty::GrdaWarehouse
  module DataSourceExtension
    extend ActiveSupport::Concern

    included do
      def convert_data_to_aggregated!
        raise 'This can only be run once per data source!' if HmisCsvTwentyTwenty::Aggregated::Enrollment.where(data_source_id: id).exists?

        copy_data_to_aggregates(enrollments, HmisCsvTwentyTwenty::Aggregated::Enrollment)
        copy_data_to_aggregates(exits, HmisCsvTwentyTwenty::Aggregated::Exit)
      end

      private def copy_data_to_aggregates(scope, destination_class)
        pseudo_importer_log = HmisCsvTwentyTwenty::Importer::ImporterLog.new(id: 0)
        scope.find_in_batches do |batch|
          look_asides = []
          batch.each do |row|
            data = row.slice(row.class.hmis_structure(version: '2020').keys)
            data.merge!(
              source_type: row.class.name,
              source_id: row.id,
              data_source_id: id,
              importer_log_id: pseudo_importer_log.id,
              pre_processed_at: Time.current,
            )
            new_item = destination_class.new(data)
            new_item.set_source_hash
            look_asides << new_item
          end
          destination_class.import(look_asides)
        end
      end
    end
  end
end
