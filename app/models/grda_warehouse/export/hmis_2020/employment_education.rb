###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::Export::HMIS2020
  class EmploymentEducation < GrdaWarehouse::Import::HMIS2020::EmploymentEducation
    include ::Export::HMIS2020::Shared
    setup_hud_column_access( GrdaWarehouse::Hud::EmploymentEducation.hud_csv_headers(version: '2020') )

    self.hud_key = :EmploymentEducationID

     # Setup an association to enrollment that allows us to pull the records even if the
    # enrollment has been deleted
    belongs_to :enrollment_with_deleted, class_name: 'GrdaWarehouse::Hud::WithDeleted::Enrollment', primary_key: [:EnrollmentID, :PersonalID, :data_source_id], foreign_key: [:EnrollmentID, :PersonalID, :data_source_id]

  end
end