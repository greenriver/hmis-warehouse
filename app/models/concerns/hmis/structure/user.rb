###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HMIS::Structure::User
  extend ActiveSupport::Concern
  include ::HMIS::Structure::Base

  included do
    self.hud_key = :UserID
    acts_as_paranoid(column: :DateDeleted)
  end

  module ClassMethods
    def hmis_configuration(version: nil)
      case version
      when '2020', nil
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
    end

    def hmis_indices(version: nil) # rubocop:disable Lint/UnusedMethodArgument
      {
        [:UserID] => nil,
        [:ExportID] => nil,
      }
    end
  end
end
