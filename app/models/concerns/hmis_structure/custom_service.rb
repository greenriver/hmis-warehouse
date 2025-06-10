###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisStructure::CustomService
  extend ActiveSupport::Concern
  include ::HmisStructure::Base

  included do
    self.hud_key = :CustomServiceID
    acts_as_paranoid(column: :DateDeleted) unless included_modules.include?(Paranoia)
  end

  module ClassMethods
    def hud_csv_file_name(version: nil) # rubocop:disable Lint/UnusedMethodArgument
      'Services.csv'
    end

    def hmis_configuration(version: nil)
      case version
      when '2020', '2022', '2024', '2026'
        {
          CustomServiceID: {
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
          UserID: {
            type: :string,
            limit: 32,
            null: false,
          },
          DateProvided: {
            type: :date,
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
          FAAmount: {
            type: :decimal,
          },
          FAStartDate: {
            type: :date,
          },
          FAEndDate: {
            type: :date,
          },
        }
      end
    end

    def hmis_indices(version: nil) # rubocop:disable Lint/UnusedMethodArgument
      {
        [:CustomServiceID] => nil,
        [:EnrollmentID] => nil,
        [:PersonalID] => nil,
        [:DateProvided] => nil,
      }
    end
  end
end
