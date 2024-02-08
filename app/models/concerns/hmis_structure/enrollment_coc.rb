###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisStructure::EnrollmentCoc
  extend ActiveSupport::Concern
  include ::HmisStructure::Base

  included do
    self.hud_key = :EnrollmentCoCID
    acts_as_paranoid(column: :DateDeleted) unless included_modules.include?(Paranoia)
  end

  module ClassMethods
    def hud_csv_file_name(version: nil) # rubocop:disable Lint/UnusedMethodArgument
      'EnrollmentCoC.csv' # case change
    end

    def hmis_configuration(version: nil)
      case version
      when '6.11', '6.12', '2020', '2022'
        {
          EnrollmentCoCID: {
            type: :string,
            limit: 32,
            null: false,
          },
          EnrollmentID: {
            type: :string,
            limit: 32,
            null: false,
          },
          HouseholdID: {
            type: :string,
            limit: 32,
            null: false,
          },
          ProjectID: {
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
          CoCCode: {
            type: :string,
            limit: 6,
            null: false,
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
        [:EnrollmentCoCID] => nil,
        [:CoCCode] => nil,
        [:ExportID] => nil,
        [:DateDeleted, :InformationDate] => {
          include: [
            :HouseholdID,
            :CoCCode,
          ],
        },
        [:EnrollmentID, :InformationDate, :DateDeleted] => {
          include: [
            :CoCCode,
          ],
        },
      }
    end
  end
end
