###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Hmis::Structure::Client
  extend ActiveSupport::Concern
  include Base

  included do
    def self.hud_csv_headers(version: nil)
      hmis_structure(version: version).keys.freeze
    end

    def self.hmis_structure(version: nil) # rubocop:disable Lint/UnusedMethodArgument
      # 2020
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
    end

    def self.hmis_indices(version: nil) # rubocop:disable Lint/UnusedMethodArgument
      [
        [:DateCreated],
        [:DateUpdated],
        [:ExportID],
        [:FirstName],
        [:LastName],
        [:PersonalID],
        [:DOB],
      ]
    end
  end
end
