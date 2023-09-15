###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisStructure::CurrentLivingSituation
  extend ActiveSupport::Concern
  include ::HmisStructure::Base

  included do
    self.hud_key = :CurrentLivingSitID
    acts_as_paranoid(column: :DateDeleted)
  end

  module ClassMethods
    def hmis_configuration(version: nil)
      case version
      when '2020', '2022'
        {
          CurrentLivingSitID: {
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
          CurrentLivingSituation: {
            type: :integer,
            null: false,
          },
          VerifiedBy: {
            type: :string,
            limit: 100,
          },
          LeaveSituation14Days: {
            type: :integer,
          },
          SubsequentResidence: {
            type: :integer,
          },
          ResourcesToObtain: {
            type: :integer,
          },
          LeaseOwn60Day: {
            type: :integer,
          },
          MovedTwoOrMore: {
            type: :integer,
          },
          LocationDetails: {
            type: :string,
            limit: 250,
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
      when '2024'
        {
          CurrentLivingSitID: {
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
          CurrentLivingSituation: {
            type: :integer,
            null: false,
          },
          CLSSubsidyType: {
            type: :integer,
          },
          VerifiedBy: {
            type: :string,
            limit: 100,
          },
          LeaveSituation14Days: {
            type: :integer,
          },
          SubsequentResidence: {
            type: :integer,
          },
          ResourcesToObtain: {
            type: :integer,
          },
          LeaseOwn60Day: {
            type: :integer,
          },
          MovedTwoOrMore: {
            type: :integer,
          },
          LocationDetails: {
            type: :string,
            limit: 250,
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
        [:CurrentLivingSitID] => nil,
        [:EnrollmentID] => nil,
        [:PersonalID] => nil,
        [:InformationDate] => nil,
        [:CurrentLivingSituation] => nil,
        [:ExportID] => nil,
      }
    end
  end
end
