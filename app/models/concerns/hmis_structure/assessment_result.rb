###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisStructure::AssessmentResult
  extend ActiveSupport::Concern
  include ::HmisStructure::Base

  included do
    self.hud_key = :AssessmentResultID
    acts_as_paranoid(column: :DateDeleted)
  end

  module ClassMethods
    def hud_csv_file_name(version: nil) # rubocop:disable Lint/UnusedMethodArgument
      'AssessmentResults.csv'
    end

    def hmis_configuration(version: nil)
      case version
      when '2020', '2022'
        {
          AssessmentResultID: {
            type: :string,
            limit: 32,
            null: false,
          },
          AssessmentID: {
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
          AssessmentResultType: {
            type: :string,
            limit: 250,
          },
          AssessmentResult: {
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
        [:AssessmentID] => nil,
        [:ExportID] => nil,
      }
    end
  end
end
