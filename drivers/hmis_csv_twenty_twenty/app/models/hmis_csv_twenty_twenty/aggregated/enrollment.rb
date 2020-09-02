###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HmisCsvTwentyTwenty::Aggregated
  class Enrollment < GrdaWarehouse::Hud::Base
    include ::HMIS::Structure::Enrollment
    include HmisCsvTwentyTwenty::Importer::ImportConcern
    include AggregatedImportConcern

    # Because GrdaWarehouse::Hud::* defines the table name, we can't use table_name_prefix :(
    self.table_name = 'hmis_2020_aggregated_enrollments'

    has_one :destination_record, **hud_assoc(:EnrollmentID, 'Enrollment')
    has_one :exit, primary_key: [:EnrollmentID, :PersonalID, :data_source_id], foreign_key: [:EnrollmentID, :PersonalID, :data_source_id], class_name: 'HmisCsvTwentyTwenty::Aggregated::Exit', autosave: false

    def self.involved_warehouse_scope(data_source_id:, project_ids:, date_range:)
      return none unless project_ids.present?

      warehouse_class.joins(:project).
        merge(GrdaWarehouse::Hud::Project.where(data_source_id: data_source_id, ProjectID: project_ids)).
        open_during_range(date_range.range)
    end

    def self.upsert_column_names(version: '2020')
      super(version: version) - [:pending_date_deleted, :processed_as]
    end

    def self.warehouse_class
      GrdaWarehouse::Hud::Enrollment
    end
  end
end
