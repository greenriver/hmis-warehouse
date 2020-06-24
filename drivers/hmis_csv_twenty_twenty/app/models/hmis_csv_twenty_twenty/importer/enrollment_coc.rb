###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HmisCsvTwentyTwenty::Importer
  class EnrollmentCoc < GrdaWarehouse::Hud::Base
    include ImportConcern
    include ::HMIS::Structure::EnrollmentCoc
    # Because GrdaWarehouse::Hud::* defines the table name, we can't use table_name_prefix :(
    self.table_name = 'hmis_2020_enrollment_cocs'

    has_one :destination_record, **hud_assoc(:EnrollmentCoCID, 'EnrollmentCoc')

    def self.clean_row_for_import(row, deidentified:) # rubocop:disable  Lint/UnusedMethodArgument
      row['HouseholdID'] = row['HouseholdID'].to_s[0..31] # limit household ids to 32 characters
      row
    end

    def self.involved_warehouse_scope(data_source_id:, project_ids:, date_range:)
      return none unless project_ids.present?

      GrdaWarehouse::Hud::EnrollmentCoc.joins(enrollment: :project).
        merge(GrdaWarehouse::Hud::Project.where(data_source_id: data_source_id, ProjectID: project_ids)).
        merge(GrdaWarehouse::Hud::Enrollment.open_during_range(date_range.range))
    end
  end
end
