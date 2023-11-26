###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisStructure::HmisParticipation
  extend ActiveSupport::Concern
  include ::HmisStructure::Base

  included do
    self.hud_key = :HMISParticipationID
    acts_as_paranoid(column: :DateDeleted) unless included_modules.include?(Paranoia)
  end

  module ClassMethods
    def hud_csv_file_name(version: nil) # rubocop:disable Lint/UnusedMethodArgument
      'HMISParticipation.csv'
    end

    def hmis_configuration(version: nil)
      case version
      when '2024'
        {
          HMISParticipationID: {
            type: :string,
            limit: 32,
            null: false,
          },
          ProjectID: {
            type: :string,
            limit: 32,
            null: false,
          },
          HMISParticipationType: {
            type: :integer,
            null: false,
          },
          HMISParticipationStatusStartDate: {
            type: :date,
            null: false,
          },
          HMISParticipationStatusEndDate: {
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
        [:HMISParticipationID] => nil,
        [:ProjectID] => nil,
        [:ExportID] => nil,
      }
    end
  end
end
