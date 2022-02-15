###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyTwo::Exporter
  class AssessmentQuestion < GrdaWarehouse::Hud::AssessmentQuestion
    include ::HmisCsvTwentyTwentyTwo::Exporter::Shared
    setup_hud_column_access(GrdaWarehouse::Hud::AssessmentQuestion.hud_csv_headers(version: '2022'))

    # Setup an association to enrollment that allows us to pull the records even if the
    # enrollment has been deleted
    belongs_to :enrollment_with_deleted, class_name: 'GrdaWarehouse::Hud::WithDeleted::Enrollment', primary_key: [:EnrollmentID, :PersonalID, :data_source_id], foreign_key: [:EnrollmentID, :PersonalID, :data_source_id], optional: true

    def apply_overrides(row, data_source_id:) # rubocop:disable Lint/UnusedMethodArgument
      row[:UserID] = 'op-system' if row[:UserID].blank?

      row
    end
  end
end
