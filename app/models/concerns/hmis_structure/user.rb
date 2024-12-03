###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisStructure::User
  extend ActiveSupport::Concern
  include ::HmisStructure::Base
  include HasPiiAttributes

  included do
    self.hud_key = :UserID
    acts_as_paranoid(column: :DateDeleted) unless included_modules.include?(Paranoia)

    def name
      "#{user_first_name} #{user_last_name}"
    end

    pii_attr :user_first_name, as: :first_name
    pii_attr :user_last_name, as: :last_name
    pii_attr :user_phone, as: :phone
    pii_attr :user_email, as: :email
  end

  module ClassMethods
    def hmis_configuration(version: nil)
      case version
      when '2020', '2022', '2024'
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
