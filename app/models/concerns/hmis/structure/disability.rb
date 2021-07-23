###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HMIS::Structure::Disability
  extend ActiveSupport::Concern
  include ::HMIS::Structure::Base

  included do
    self.hud_key = :DisabilitiesID
    acts_as_paranoid(column: :DateDeleted)
  end

  module ClassMethods
    def hud_csv_file_name(version: nil) # rubocop:disable Lint/UnusedMethodArgument
      'Disabilities.csv'
    end

    def hmis_configuration(version: nil)
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
        }.freeze
      when '2022'
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
          AntiRetroviral: {
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
        }.freeze
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
      }.freeze
    end
  end
end
