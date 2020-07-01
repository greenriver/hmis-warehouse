###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HmisCsvTwentyTwenty::Aggregator
  class Enrollment < GrdaWarehouse::Hud::Base
    include HmisCsvTwentyTwenty::Importer::ImportConcern
    include ::HMIS::Structure::Enrollment
    # Because GrdaWarehouse::Hud::* defines the table name, we can't use table_name_prefix :(
    self.table_name = 'hmis_2020_aggregated_enrollments'

    has_one :destination_record, **hud_assoc(:EnrollmentID, 'Enrollment')

    def self.involved_warehouse_scope(data_source_id:, project_ids:, date_range:)
      return none unless project_ids.present?

      GrdaWarehouse::Hud::Enrollment.joins(:project).
        merge(GrdaWarehouse::Hud::Project.where(data_source_id: data_source_id, ProjectID: project_ids)).
        open_during_range(date_range.range)
    end
  end
end
