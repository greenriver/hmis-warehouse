###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisStructure::CeParticipation
  extend ActiveSupport::Concern
  include ::HmisStructure::Base

  included do
    self.hud_key = :CEParticipationID
    acts_as_paranoid(column: :DateDeleted)
  end

  module ClassMethods
    def hud_csv_file_name(version: nil) # rubocop:disable Lint/UnusedMethodArgument
      'CEParticipation.csv'
    end

    def hmis_configuration(version: nil)
      case version
      when '2024'
        {
          CEParticipationID: {
            type: :string,
            limit: 32,
            null: false,
          },
          ProjectID: {
            type: :string,
            limit: 32,
            null: false,
          },
          AccessPoint: {
            type: :integer,
            null: false,
          },
          PreventionAssessment: {
            type: :integer,
          },
          CrisisAssessment: {
            type: :integer,
          },
          HousingAssessment: {
            type: :integer,
          },
          DirectServices: {
            type: :integer,
          },
          ReceivesReferrals: {
            type: :integer,
          },
          CEParticipationStatusStartDate: {
            type: :date,
            null: false,
          },
          CEParticipationStatusEndDate: {
            type: :date,
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
        [:CEParticipationID] => nil,
        [:ProjectID] => nil,
        [:ExportID] => nil,
      }
    end
  end
end
