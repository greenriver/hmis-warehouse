###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisStructure::CustomAssessment
  extend ActiveSupport::Concern
  include ::HmisStructure::Base

  included do
    self.hud_key = :CustomAssessmentID
    acts_as_paranoid(column: :DateDeleted) unless included_modules.include?(Paranoia)
  end

  module ClassMethods
    def hmis_configuration(version: nil)
      case version
      when '2020', '2022', '2024', '2026'
        {
          CustomAssessmentID: {
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
          UserID: {
            type: :string,
            limit: 32,
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
          DateDeleted: {
            type: :datetime,
          },
        }
      end
    end

    def hmis_indices(version: nil) # rubocop:disable Lint/UnusedMethodArgument
      {
        [:CustomAssessmentID] => nil,
        [:EnrollmentID] => nil,
        [:PersonalID] => nil,
        [:AssessmentDate] => nil,
      }
    end
  end
end
