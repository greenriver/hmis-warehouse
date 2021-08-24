###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HMIS::Structure::ProjectCoc
  extend ActiveSupport::Concern
  include ::HMIS::Structure::Base

  included do
    self.hud_key = :ProjectCoCID
    acts_as_paranoid(column: :DateDeleted)
  end

  module ClassMethods
    def hud_csv_file_name(version: nil) # rubocop:disable Lint/UnusedMethodArgument
      'ProjectCoC.csv'
    end

    def hmis_configuration(version: nil)
      case version
      when '5.1', '6.11', '6.12'
        {
          ProjectCoCID: {
            type: :string,
            limit: 32,
            null: false,
          },
          ProjectID: {
            type: :string,
            limit: 32,
            null: false,
          },
          CoCCode: {
            type: :string,
            limit: 6,
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
      when '2020', '2022', nil
        {
          ProjectCoCID: {
            type: :string,
            limit: 32,
            null: false,
          },
          ProjectID: {
            type: :string,
            limit: 32,
            null: false,
          },
          CoCCode: {
            type: :string,
            limit: 6,
            null: false,
          },
          Geocode: {
            type: :string,
            limit: 6,
            null: false,
          },
          Address1: {
            type: :string,
            limit: 100,
          },
          Address2: {
            type: :string,
            limit: 100,
          },
          City: {
            type: :string,
            limit: 50,
          },
          State: {
            type: :string,
            limit: 2,
          },
          Zip: {
            type: :string,
            limit: 5,
          },
          GeographyType: {
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
    end

    def hmis_indices(version: nil) # rubocop:disable Lint/UnusedMethodArgument
      {
        [:DateCreated] => nil,
        [:DateUpdated] => nil,
        [:ProjectCoCID] => nil,
        [:ProjectID, :CoCCode] => nil,
        [:ExportID] => nil,
      }
    end
  end
end
