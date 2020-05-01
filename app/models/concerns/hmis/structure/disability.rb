###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HMIS::Structure::Disability
  extend ActiveSupport::Concern
  include ::HMIS::Structure::Base

  module ClassMethods
    def hmis_structure(version: nil)
      case version
      when '6.11', '6.12', '2020', nil
        {
          DisabilitiesID: {
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
          DisabilityType: {
            type: :integer,
            null: false,
          },
          DisabilityResponse: {
            type: :integer,
            null: false,
          },
          IndefiniteAndImpairs: {
            type: :integer,
          },
          TCellCountAvailable: {
            type: :integer,
          },
          TCellCount: {
            type: :integer,
          },
          TCellSource: {
            type: :integer,
          },
          ViralLoadAvailable: {
            type: :integer,
          },
          ViralLoad: {
            type: :integer,
          },
          ViralLoadSource: {
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
        [:DisabilitiesID] => nil,
        [:ExportID] => nil,
      }
    end
  end
end
