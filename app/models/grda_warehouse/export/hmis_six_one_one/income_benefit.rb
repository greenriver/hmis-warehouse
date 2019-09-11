###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::Export::HMISSixOneOne
  class IncomeBenefit < GrdaWarehouse::Import::HMISSixOneOne::IncomeBenefit
    include ::Export::HMISSixOneOne::Shared
    setup_hud_column_access( GrdaWarehouse::Hud::IncomeBenefit.hud_csv_headers(version: '6.11') )

    self.hud_key = :IncomeBenefitsID

     # Setup an association to enrollment that allows us to pull the records even if the
    # enrollment has been deleted
    belongs_to :enrollment_with_deleted, class_name: 'GrdaWarehouse::Hud::WithDeleted::Enrollment', primary_key: [:EnrollmentID, :PersonalID, :data_source_id], foreign_key: [:EnrollmentID, :PersonalID, :data_source_id]

    def apply_overrides row, data_source_id:

      # Technical limit of HMIS spec is 50 characters
      row[:OtherInsuranceIdentify] = row[:OtherInsuranceIdentify][0...50] if row[:OtherInsuranceIdentify]
      return row
    end
  end
end