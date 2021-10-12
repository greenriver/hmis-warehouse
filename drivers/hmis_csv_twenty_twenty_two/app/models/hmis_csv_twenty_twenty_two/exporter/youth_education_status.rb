###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyTwo::Exporter
  class YouthEducationStatus < GrdaWarehouse::Hud::YouthEducationStatus
    include ::HmisCsvTwentyTwentyTwo::Exporter::Shared
    setup_hud_column_access(GrdaWarehouse::Hud::YouthEducationStatus.hud_csv_headers(version: '2022'))

    # Setup an association to enrollment that allows us to pull the records even if the
    # enrollment has been deleted
    belongs_to :enrollment_with_deleted, class_name: 'GrdaWarehouse::Hud::WithDeleted::Enrollment', primary_key: [:EnrollmentID, :PersonalID, :data_source_id], foreign_key: [:EnrollmentID, :PersonalID, :data_source_id]

    def apply_overrides(row, data_source_id:) # rubocop:disable Lint/UnusedMethodArgument
      # Required by HUD spec, not always provided 99 is not valid, but we can't really guess
      row[:DataCollectionStage] = 99 if row[:DataCollectionStage].blank?
      row[:UserID] = 'op-system' if row[:UserID].blank?

      row
    end
  end
end
