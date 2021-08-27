###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HMIS::Structure::Funder
  extend ActiveSupport::Concern
  include ::HMIS::Structure::Base

  included do
    self.hud_key = :FunderID
    acts_as_paranoid(column: :DateDeleted)
  end

  module ClassMethods
    def hmis_configuration(version: nil)
      case version
      when '5.1', '6.11', '6.12'
        {
          FunderID: {
            type: :string,
            limit: 32,
            null: false,
          },
          ProjectID: {
            type: :string,
            limit: 32,
            null: false,
          },
          Funder: {
            type: :string,
            limit: 50,
            null: false,
          },
          GrantID: {
            type: :string,
            limit: 50,
            null: false,
          },
          StartDate: {
            type: :date,
            null: false,
          },
          EndDate: {
            type: :date,
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
      when '2020', '2022', nil
        {
          FunderID: {
            type: :string,
            limit: 32,
            null: false,
          },
          ProjectID: {
            type: :string,
            limit: 32,
            null: false,
          },
          Funder: {
            type: :integer,
            null: false,
          },
          OtherFunder: {
            type: :string,
            limit: 50,
          },
          GrantID: {
            type: :string,
            limit: 32,
            null: false,
          },
          StartDate: {
            type: :date,
            null: false,
          },
          EndDate: {
            type: :date,
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
        [:FunderID] => nil,
        [:ExportID] => nil,
      }
    end
  end
end
