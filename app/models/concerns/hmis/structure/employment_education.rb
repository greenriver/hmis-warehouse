###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HMIS::Structure::EmploymentEducation
  extend ActiveSupport::Concern
  include ::HMIS::Structure::Base

  included do
    self.hud_key = :EmploymentEducationID
    acts_as_paranoid(column: :DateDeleted)
  end

  module ClassMethods
    def hmis_configuration(version: nil)
      case version
      when '6.11', '6.12', '2020', '2022', nil
        {
          EmploymentEducationID: {
            type: :string,
            limit: 32,
            null: false,
          },
          EnrollmentID: {
            type: :string,
            limit: 32,
            null: false,
          },
          PersonalID: {
            type: :string,
            limit: 32,
            null: false,
          },
          InformationDate: {
            type: :date,
            null: false,
          },
          LastGradeCompleted: {
            type: :integer,
          },
          SchoolStatus: {
            type: :integer,
          },
          Employed: {
            type: :integer,
          },
          EmploymentType: {
            type: :integer,
          },
          NotEmployedReason: {
            type: :integer,
          },
          DataCollectionStage: {
            type: :integer,
            null: false,
          },
          DateCreated: {
            type: :datetime,
            null: false,
          },
          DateUpdated: {
            type: :datetime,
            null: false,
          },
          UserID: {
            type: :string,
            limit: 32,
            null: false,
          },
          DateDeleted: {
            type: :datetime,
          },
          ExportID: {
            type: :string,
            limit: 32,
            null: false,
          },
        }
      end
    end

    def hmis_indices(version: nil) # rubocop:disable Lint/UnusedMethodArgument
      {
        [:DateCreated] => nil,
        [:DateUpdated] => nil,
        [:EnrollmentID] => nil,
        [:PersonalID] => nil,
        [:EmploymentEducationID] => nil,
        [:ExportID] => nil,
      }
    end
  end
end
