###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HMIS::Structure::Export
  extend ActiveSupport::Concern
  include ::HMIS::Structure::Base

  included do
    self.hud_key = :ExportID
  end

  module ClassMethods
    def hud_paranoid_column
      nil
    end

    def hmis_configuration(version: nil)
      case version
      when '6.11', '6.12', '2020'
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
      when '2022'
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
          CSVVersion: {
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
    end

    def hmis_indices(version: nil) # rubocop:disable Lint/UnusedMethodArgument
      {
        [:ExportID] => nil,
      }
    end
  end
end
