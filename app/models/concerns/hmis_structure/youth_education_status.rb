###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisStructure::YouthEducationStatus
  extend ActiveSupport::Concern
  include ::HmisStructure::Base

  included do
    self.hud_key = :YouthEducationStatusID
    acts_as_paranoid(column: :DateDeleted)
  end

  module ClassMethods
    def hmis_configuration(version: nil)
      case version
      when '2022'
        {
          YouthEducationStatusID: {
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
          CurrentSchoolAttend: {
            type: :integer,
          },
          MostRecentEdStatus: {
            type: :integer,
          },
          CurrentEdStatus: {
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
        [:YouthEducationStatusID] => nil,
        [:EnrollmentID] => nil,
        [:PersonalID] => nil,
        [:InformationDate] => nil,
        [:ExportID] => nil,
      }
    end
  end
end
