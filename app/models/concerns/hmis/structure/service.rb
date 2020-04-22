###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HMIS::Structure::Service
  extend ActiveSupport::Concern
  include ::HMIS::Structure::Base

  module ClassMethods
    def hud_csv_headers(version: nil)
      hmis_structure(version: version).keys.freeze
    end

    def hmis_structure(version: nil)
      case version
      when '6.11', '6.12', '2020', nil
        {
          ServicesID: {
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
          DateProvided: {
            type: :date,
            null: false,
          },
          RecordType: {
            type: :integer,
            null: false,
          },
          TypeProvided: {
            type: :integer,
            null: false,
          },
          OtherTypeProvided: {
            type: :string,
            limit: 50,
          },
          SubTypeProvided: {
            type: :integer,
          },
          FAAmount: {
            type: :string,
            limit: 50,
          },
          ReferralOutcome: {
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
      [
        [:DateCreated],
        [:DateDeleted],
        [:DateProvided],
        [:RecordType],
        [:RecordType, :DateProvided],
        [:DateUpdated],
        [:EnrollmentID],
        [:EnrollmentID, :PersonalID],
        [:PersonalID],
        [:PersonalID, :RecordType, :EnrollmentID, :DateProvided],
        [:ServicesID],
        [:ExportID],
      ]
    end
  end
end
