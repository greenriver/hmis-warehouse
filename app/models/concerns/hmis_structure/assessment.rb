###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisStructure::Assessment
  extend ActiveSupport::Concern
  include ::HmisStructure::Base

  included do
    self.hud_key = :AssessmentID
    acts_as_paranoid(column: :DateDeleted)
  end

  module ClassMethods
    def hmis_configuration(version: nil)
      case version
      when '2020', '2022'
        {
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
          AssessmentDate: {
            type: :date,
            null: false,
          },
          AssessmentLocation: {
            type: :string,
            limit: 250,
            null: false,
          },
          AssessmentType: {
            type: :integer,
            null: false,
          },
          AssessmentLevel: {
            type: :integer,
            null: false,
          },
          PrioritizationStatus: {
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
        [:AssessmentID] => nil,
        [:EnrollmentID] => nil,
        [:PersonalID] => nil,
        [:AssessmentDate] => nil,
        [:ExportID] => nil,
      }
    end
  end
end
