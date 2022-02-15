###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwenty::Aggregated
  class Exit < GrdaWarehouse::Hud::Base
    include ::HMIS::Structure::Exit
    include HmisCsvTwentyTwenty::Importer::ImportConcern
    include AggregatedImportConcern
    include ArelHelper

    # Because GrdaWarehouse::Hud::* defines the table name, we can't use table_name_prefix :(
    self.table_name = 'hmis_2020_aggregated_exits'

    has_one :destination_record, **hud_assoc(:ExitID, 'Exit')
    belongs_to :enrollment, primary_key: [:EnrollmentID, :PersonalID, :data_source_id], foreign_key: [:EnrollmentID, :PersonalID, :data_source_id], class_name: 'HmisCsvTwentyTwenty::Aggregated::Enrollment', autosave: false, optional: true

    def self.involved_warehouse_scope(data_source_id:, project_ids:, date_range:)
      return none unless project_ids.present?

      # this has to be a bit convoluted because active record doesn't rename the exit joins appropriately
      warehouse_class.where(
        id: GrdaWarehouse::Hud::Enrollment.open_during_range(date_range.range).
          joins(:project).
          merge(GrdaWarehouse::Hud::Project.where(data_source_id: data_source_id, ProjectID: project_ids)).
          select(ex_t[:id]),
      )
    end

    def self.warehouse_class
      GrdaWarehouse::Hud::Exit
    end
  end
end
