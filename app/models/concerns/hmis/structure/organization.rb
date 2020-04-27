###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HMIS::Structure::Organization
  extend ActiveSupport::Concern
  include ::HMIS::Structure::Base

  module ClassMethods
    def hud_csv_headers(version: nil)
      hmis_structure(version: version).keys.freeze
    end

    def hmis_structure(version: nil)
      case version
      when '2020'
        {
          OrganizationID: {
            type: :string,
            limit: 32,
            null: false,
          },
          OrganizationName: {
            type: :string,
            limit: 50,
            null: false,
          },
          VictimServicesProvider: {
            type: :integer,
            null: false,
          },
          OrganizationCommonName: {
            type: :string,
            limit: 50,
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
      else
        {
          OrganizationID: {
            type: :string,
            limit: 32,
            null: false,
          },
          OrganizationName: {
            type: :string,
            limit: 50,
            null: false,
          },
          OrganizationCommonName: {
            type: :string,
            limit: 50,
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
        [:OrganizationID] => nil,
        [:ExportID] => nil,
      }
    end
  end
end
