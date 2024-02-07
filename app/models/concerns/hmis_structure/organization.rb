###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisStructure::Organization
  extend ActiveSupport::Concern
  include ::HmisStructure::Base

  included do
    self.hud_key = :OrganizationID
    acts_as_paranoid(column: :DateDeleted) unless included_modules.include?(Paranoia)
  end

  module ClassMethods
    def hmis_configuration(version: nil)
      case version
      when '6.11', '6.12'
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
      when '2022'
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
          VictimServiceProvider: {
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
      when '2024'
        {
          OrganizationID: {
            type: :string,
            limit: 32,
            null: false,
          },
          OrganizationName: {
            type: :string,
            limit: 200,
            null: false,
          },
          VictimServiceProvider: {
            type: :integer,
            null: false,
          },
          OrganizationCommonName: {
            type: :string,
            limit: 200,
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
