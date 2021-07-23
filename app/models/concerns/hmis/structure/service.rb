###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HMIS::Structure::Service
  extend ActiveSupport::Concern
  include ::HMIS::Structure::Base

  included do
    self.hud_key = :ServicesID
    acts_as_paranoid(column: :DateDeleted)
  end

  module ClassMethods
    def hmis_configuration(version: nil)
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
      when '2022'
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
          MovingOnOtherType: {
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
        [:DateDeleted] => nil,
        [:DateProvided] => nil,
        [:RecordType] => nil,
        [:RecordType, :DateProvided] => nil,
        [:RecordType, :DateDeleted] => nil,
        [:DateUpdated] => nil,
        [:EnrollmentID] => nil,
        [:EnrollmentID, :PersonalID] => nil,
        [:EnrollmentID, :RecordType, :DateDeleted, :DateProvided] => nil,
        [:PersonalID] => nil,
        [:PersonalID, :RecordType, :EnrollmentID, :DateProvided] => nil,
        [:ServicesID] => nil,
        [:ExportID] => nil,
      }
    end
  end
end
