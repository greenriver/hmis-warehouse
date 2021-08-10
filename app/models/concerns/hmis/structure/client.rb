###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HMIS::Structure::Client
  extend ActiveSupport::Concern
  include ::HMIS::Structure::Base

  included do
    self.hud_key = :PersonalID
    self.additional_upsert_columns = [:demographic_dirty]
    acts_as_paranoid(column: :DateDeleted)
  end

  module ClassMethods
    def hmis_configuration(version: nil)
      case version
      when '6.11', '6.12', '2020', nil
        {
          PersonalID: {
            type: :string,
            limit: 32,
            null: false,
          },
          FirstName: {
            type: :string,
            limit: 50,
          },
          MiddleName: {
            type: :string,
            limit: 50,
          },
          LastName: {
            type: :string,
            limit: 50,
          },
          NameSuffix: {
            type: :string,
            limit: 50,
          },
          NameDataQuality: {
            type: :integer,
            null: false,
          },
          SSN: {
            type: :string,
            limit: 9,
          },
          SSNDataQuality: {
            type: :string,
            null: false,
          },
          DOB: {
            type: :date,
          },
          DOBDataQuality: {
            type: :string,
            null: false,
          },
          AmIndAKNative: {
            type: :integer,
            null: false,
          },
          Asian: {
            type: :integer,
            null: false,
          },
          BlackAfAmerican: {
            type: :integer,
            null: false,
          },
          NativeHIOtherPacific: {
            type: :integer,
            null: false,
          },
          White: {
            type: :integer,
            null: false,
          },
          RaceNone: {
            type: :integer,
          },
          Ethnicity: {
            type: :integer,
            null: false,
          },
          Gender: {
            type: :integer,
            null: false,
          },
          VeteranStatus: {
            type: :integer,
            null: false,
          },
          YearEnteredService: {
            type: :integer,
          },
          YearSeparated: {
            type: :integer,
          },
          WorldWarII: {
            type: :integer,
          },
          KoreanWar: {
            type: :integer,
          },
          VietnamWar: {
            type: :integer,
          },
          DesertStorm: {
            type: :integer,
          },
          AfghanistanOEF: {
            type: :integer,
          },
          IraqOIF: {
            type: :integer,
          },
          IraqOND: {
            type: :integer,
          },
          OtherTheater: {
            type: :integer,
          },
          MilitaryBranch: {
            type: :integer,
          },
          DischargeStatus: {
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
          PersonalID: {
            type: :string,
            limit: 32,
            null: false,
          },
          FirstName: {
            type: :string,
            limit: 50,
          },
          MiddleName: {
            type: :string,
            limit: 50,
          },
          LastName: {
            type: :string,
            limit: 50,
          },
          NameSuffix: {
            type: :string,
            limit: 50,
          },
          NameDataQuality: {
            type: :integer,
            null: false,
          },
          SSN: {
            type: :string,
            limit: 9,
          },
          SSNDataQuality: {
            type: :string,
            null: false,
          },
          DOB: {
            type: :date,
          },
          DOBDataQuality: {
            type: :string,
            null: false,
          },
          AmIndAKNative: {
            type: :integer,
            null: false,
          },
          Asian: {
            type: :integer,
            null: false,
          },
          BlackAfAmerican: {
            type: :integer,
            null: false,
          },
          NativeHIOtherPacific: {
            type: :integer,
            null: false,
          },
          White: {
            type: :integer,
            null: false,
          },
          RaceNone: {
            type: :integer,
          },
          Ethnicity: {
            type: :integer,
            null: false,
          },
          Female: {
            type: :integer,
            null: false,
          },
          Male: {
            type: :integer,
            null: false,
          },
          GenderOther: {
            type: :integer,
            null: false,
          },
          Transgender: {
            type: :integer,
            null: false,
          },
          Questioning: {
            type: :integer,
            null: false,
          },
          GenderNone: {
            type: :integer,
            null: false,
          },
          VeteranStatus: {
            type: :integer,
            null: false,
          },
          YearEnteredService: {
            type: :integer,
          },
          YearSeparated: {
            type: :integer,
          },
          WorldWarII: {
            type: :integer,
          },
          KoreanWar: {
            type: :integer,
          },
          VietnamWar: {
            type: :integer,
          },
          DesertStorm: {
            type: :integer,
          },
          AfghanistanOEF: {
            type: :integer,
          },
          IraqOIF: {
            type: :integer,
          },
          IraqOND: {
            type: :integer,
          },
          OtherTheater: {
            type: :integer,
          },
          MilitaryBranch: {
            type: :integer,
          },
          DischargeStatus: {
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
        [:DateUpdated] => nil,
        [:ExportID] => nil,
        [:FirstName] => nil,
        [:LastName] => nil,
        [:PersonalID] => nil,
        [:VeteranStatus] => nil,
        [:DOB] => nil,
      }
    end
  end
end
