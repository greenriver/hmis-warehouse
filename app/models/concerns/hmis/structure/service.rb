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

    def hmis_structure(version: nil) # rubocop:disable Lint/UnusedMethodArgument
      # 2020
      {
        ExportID: {
          type: :string,
          limit: 32,
          null: false,
        },
        SourceType: {
          type: :integer,
          null: false,
        },
        SourceID: {
          type: :string,
          limit: 32,
        },
        SourceName: {
          type: :string,
          limit: 50,
        },
        SourceContactFirst: {
          type: :string,
          limit: 50,
        },
        SourceContactLast: {
          type: :string,
          limit: 50,
        },
        SourceContactPhone: {
          type: :string,
          limit: 10,
        },
        SourceContactExtension: {
          type: :string,
          limit: 5,
        },
        SourceContactEmail: {
          type: :string,
          limit: 320,
        },
        ExportDate: {
          type: :datetime,
          null: false,
        },
        ExportStartDate: {
          type: :date,
          null: false,
        },
        ExportEndDate: {
          type: :date,
          null: false,
        },
        SoftwareName: {
          type: :string,
          limit: 50,
          null: false,
        },
        SoftwareVersion: {
          type: :string,
          limit: 50,
        },
        ExportPeriodType: {
          type: :integer,
          null: false,
        },
        ExportDirective: {
          type: :integer,
          null: false,
        },
        HashStatus: {
          type: :integer,
          null: false,
        },
      }
    end

    def hmis_indices(version: nil) # rubocop:disable Lint/UnusedMethodArgument
      [
        [:ExportID],
      ]
    end
  end
end
