###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HMIS::Structure::Affiliation
  extend ActiveSupport::Concern
  include ::HMIS::Structure::Base

  module ClassMethods
    def hud_csv_headers(version: nil)
      hmis_structure(version: version).keys.freeze
    end

    def hmis_structure(version: nil) # rubocop:disable Lint/UnusedMethodArgument
      # 2020
      {
        AffiliationID: {
          type: :string,
          limit: 32,
          null: false,
        },
        ProjectID: {
          type: :string,
          limit: 32,
          null: false,
        },
        ResProjectID: {
          type: :string,
          limit: 32,
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

    def hmis_indices(version: nil) # rubocop:disable Lint/UnusedMethodArgument
      [
        [:ExportID],
      ]
    end
  end
end
