###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HMIS::Structure::Event
  extend ActiveSupport::Concern
  include ::HMIS::Structure::Base

  included do
    self.hud_key = :EventID
    acts_as_paranoid(column: :DateDeleted)
  end

  module ClassMethods
    def hmis_configuration(version: nil)
      case version
      when '2020', '2022', nil
        {
          EventID: {
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
          EventDate: {
            type: :date,
            null: false,
          },
          Event: {
            type: :integer,
            null: false,
          },
          ProbSolDivRRResult: {
            type: :integer,
          },
          ReferralCaseManageAfter: {
            type: :integer,
          },
          LocationCrisisOrPHHousing: {
            type: :string,
            limit: 250,
          },
          ReferralResult: {
            type: :integer,
          },
          ResultDate: {
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
        [:EventID] => nil,
        [:EnrollmentID] => nil,
        [:PersonalID] => nil,
        [:EventDate] => nil,
        [:ExportID] => nil,
      }
    end
  end
end
