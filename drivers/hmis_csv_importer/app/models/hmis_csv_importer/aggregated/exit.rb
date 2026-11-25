###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvImporter::Aggregated
  class Exit < GrdaWarehouse::Hud::Base
    include ::HmisStructure::Exit
    include HmisCsvImporter::Importer::ImportConcern
    include AggregatedImportConcern

    self.table_name = 'hmis_aggregated_exits'

    has_one :destination_record, **hud_assoc(:ExitID, 'Exit')
    belongs_to :enrollment, primary_key: [:EnrollmentID, :PersonalID, :data_source_id], foreign_key: [:EnrollmentID, :PersonalID, :data_source_id], class_name: 'HmisCsvImporter::Aggregated::Enrollment', autosave: false, optional: true

    def self.warehouse_class
      GrdaWarehouse::Hud::Exit
    end

    def self.migrate_to_unversioned
      connection.execute 'INSERT INTO hmis_aggregated_exits SELECT * FROM hmis_2020_aggregated_exits'
    end

    def self.keys_for_migrations(version: hud_csv_version)
      hmis_configuration(version: version).keys.map(&:to_s) + [
        'id',
        'data_source_id',
        'importer_log_id',
        'pre_processed_at',
        'source_id',
        'source_type',
      ]
    end
  end
end
