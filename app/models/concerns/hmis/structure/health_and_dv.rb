###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HMIS::Structure::HealthAndDv
  extend ActiveSupport::Concern
  include ::HMIS::Structure::Base

  included do
    self.hud_key = :HealthAndDVID
    acts_as_paranoid(column: :DateDeleted)
  end

  module ClassMethods
    def hud_csv_file_name(version: nil) # rubocop:disable Lint/UnusedMethodArgument
      'HealthAndDV.csv'
    end

    def hmis_configuration(version: nil)
      case version
      when '6.11', '6.12', '2020'
        {
          HealthAndDVID: {
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
          DomesticViolenceVictim: {
            type: :integer,
          },
          WhenOccurred: {
            type: :integer,
          },
          CurrentlyFleeing: {
            type: :integer,
          },
          GeneralHealthStatus: {
            type: :integer,
          },
          DentalHealthStatus: {
            type: :integer,
          },
          MentalHealthStatus: {
            type: :integer,
          },
          PregnancyStatus: {
            type: :integer,
          },
          DueDate: {
            type: :date,
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
      when '2022', nil
        {
          HealthAndDVID: {
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
          DomesticViolenceVictim: {
            type: :integer,
          },
          WhenOccurred: {
            type: :integer,
          },
          CurrentlyFleeing: {
            type: :integer,
          },
          GeneralHealthStatus: {
            type: :integer,
          },
          DentalHealthStatus: {
            type: :integer,
          },
          MentalHealthStatus: {
            type: :integer,
          },
          PregnancyStatus: {
            type: :integer,
          },
          DueDate: {
            type: :date,
          },
          LifeValue: {
            type: :integer,
          },
          SupportfromOthers: {
            type: :integer,
          },
          BounceBack: {
            type: :integer,
          },
          FeelingFrequency: {
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
        [:HealthAndDVID] => nil,
        [:ExportID] => nil,
      }
    end
  end
end
