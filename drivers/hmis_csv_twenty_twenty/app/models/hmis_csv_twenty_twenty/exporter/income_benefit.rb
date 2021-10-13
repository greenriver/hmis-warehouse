###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwenty::Exporter
  class IncomeBenefit < GrdaWarehouse::Hud::IncomeBenefit
    include ::HmisCsvTwentyTwenty::Exporter::Shared
    setup_hud_column_access(GrdaWarehouse::Hud::IncomeBenefit.hud_csv_headers(version: '2020'))

    # Setup an association to enrollment that allows us to pull the records even if the
    # enrollment has been deleted
    belongs_to :enrollment_with_deleted, class_name: 'GrdaWarehouse::Hud::WithDeleted::Enrollment', primary_key: [:EnrollmentID, :PersonalID, :data_source_id], foreign_key: [:EnrollmentID, :PersonalID, :data_source_id], optional: true

    def apply_overrides(row, data_source_id:) # rubocop:disable Lint/UnusedMethodArgument
      # Technical limit of HMIS spec is 50 characters
      row[:OtherInsuranceIdentify] = row[:OtherInsuranceIdentify][0...50] if row[:OtherInsuranceIdentify]
      row[:OtherIncomeSourceIdentify] = row[:OtherIncomeSourceIdentify][0...50] if row[:OtherIncomeSourceIdentify]
      row[:OtherBenefitsSourceIdentify] = row[:OtherBenefitsSourceIdentify][0...50] if row[:OtherBenefitsSourceIdentify]
      # Required by HUD spec, not always provided 99 is not valid, but we can't really guess
      row[:DataCollectionStage] = 99 if row[:DataCollectionStage].blank?

      row
    end
  end
end
