###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwenty::GrdaWarehouse::Hud
  module ProjectExtension
    extend ActiveSupport::Concern

    included do
      has_many :imported_items, class_name: 'HmisCsvTwentyTwenty::Importer::Project', primary_key: [:ProjectID, :data_source_id], foreign_key: [:ProjectID, :data_source_id]
      has_many :loaded_items, class_name: 'HmisCsvTwentyTwenty::Loader::Project', primary_key: [:ProjectID, :data_source_id], foreign_key: [:ProjectID, :data_source_id]
      has_many :involved_in_imports, class_name: 'HmisCsvTwentyTwenty::Importer::InvolvedInImport', as: :warehouse_record

      def convert_to_aggregated!
        existing = HmisCsvTwentyTwenty::Aggregated::Enrollment.where(data_source_id: data_source_id, ProjectID: self.ProjectID).exists?
        raise 'This can only be run once per data source!' if existing

        data_source.update(
          import_aggregators: {
            'Enrollment' => ['HmisCsvTwentyTwenty::Aggregated::CombineEnrollments'],
          },
        )
        update(combine_enrollments: true)

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
              data_source_id: data_source_id,
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
