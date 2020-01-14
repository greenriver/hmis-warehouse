###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::Export::HmisTwentyTwenty
  class EnrollmentCoc < GrdaWarehouse::Import::HmisTwentyTwenty::EnrollmentCoc
    include ::Export::HmisTwentyTwenty::Shared
    setup_hud_column_access( GrdaWarehouse::Hud::EnrollmentCoc.hud_csv_headers(version: '2020') )

    self.hud_key = :EnrollmentCoCID

    # Setup an association to enrollment that allows us to pull the records even if the
    # enrollment has been deleted
    belongs_to :enrollment_with_deleted, class_name: 'GrdaWarehouse::Hud::WithDeleted::Enrollment', primary_key: [:EnrollmentID, :PersonalID, :data_source_id], foreign_key: [:EnrollmentID, :PersonalID, :data_source_id]


    # HouseholdID is required, but often not provided, send some sane defaults
    # Also unique the HouseholdID to a data source
    def apply_overrides row, data_source_id:
      if row[:HouseholdID].blank?
        row[:HouseholdID] = "p_#{client_export_id(row[:PersonalID], data_source_id)}"
      else
        row[:HouseholdID] = "#{data_source_id}_#{(row[:HouseholdID])}"
      end

      return row
    end
  end
end