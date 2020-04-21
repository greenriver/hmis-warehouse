###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HMIS::Structure::User
  extend ActiveSupport::Concern
  include ::HMIS::Structure::Base

  module ClassMethods
    def hud_csv_headers(version: nil)
      hmis_structure(version: version).keys.freeze
    end

    def hmis_structure(version: nil) # rubocop:disable Lint/UnusedMethodArgument
      # 2020
      {
        UserID: {
          type: :string,
          limit: 32,
          null: false,
        },
        UserFirstName: {
          type: :string,
          limit: 50,
        },
        UserLastName: {
          type: :string,
          limit: 50,
        },
        UserPhone: {
          type: :string,
          limit: 10,
        },
        UserExtension: {
          type: :string,
          limit: 5,
        },
        UserEmail: {
          type: :string,
          limit: 320,
        },
        DateCreated: {
          type: :datetime,
          null: false,
        },
        DateUpdated: {
          type: :datetime,
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
        [:UserID],
        [:ExportID],
      ]
    end
  end
end
