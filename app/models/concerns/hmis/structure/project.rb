###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HMIS::Structure::Project
  extend ActiveSupport::Concern
  include ::HMIS::Structure::Base

  included do
    self.hud_key = :ProjectID
    acts_as_paranoid(column: :DateDeleted)
  end

  module ClassMethods
    def hmis_configuration(version: nil)
      case version
      when '6.11', '6.12'
        {
          ProjectID: {
            type: :string,
            limit: 32,
            null: false,
          },
          OrganizationID: {
            type: :string,
            limit: 32,
            null: false,
          },
          ProjectName: {
            type: :string,
            limit: 50,
            null: false,
          },
          ProjectCommonName: {
            type: :string,
            limit: 50,
          },
          OperatingStartDate: {
            type: :date,
            null: false,
          },
          OperatingEndDate: {
            type: :date,
          },
          ContinuumProject: {
            type: :integer,
            null: false,
          },
          ProjectType: {
            type: :integer,
          },
          ResidentialAffiliation: {
            type: :integer,
          },
          TrackingMethod: {
            type: :integer,
          },
          TargetPopulation: {
            type: :integer,
          },
          VictimServicesProvider: {
            type: :integer,
          },
          HousingType: {
            type: :integer,
          },
          PITCount: {
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
      when '2020'
        {
          ProjectID: {
            type: :string,
            limit: 32,
            null: false,
          },
          OrganizationID: {
            type: :string,
            limit: 32,
            null: false,
          },
          ProjectName: {
            type: :string,
            limit: 50,
            null: false,
          },
          ProjectCommonName: {
            type: :string,
            limit: 50,
          },
          OperatingStartDate: {
            type: :date,
            null: false,
          },
          OperatingEndDate: {
            type: :date,
          },
          ContinuumProject: {
            type: :integer,
            null: false,
          },
          ProjectType: {
            type: :integer,
          },
          HousingType: {
            type: :integer,
          },
          ResidentialAffiliation: {
            type: :integer,
          },
          TrackingMethod: {
            type: :integer,
          },
          HMISParticipatingProject: {
            type: :integer,
            null: false,
          },
          TargetPopulation: {
            type: :integer,
          },
          PITCount: {
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
      when '2022'
        {
          ProjectID: {
            type: :string,
            limit: 32,
            null: false,
          },
          OrganizationID: {
            type: :string,
            limit: 32,
            null: false,
          },
          ProjectName: {
            type: :string,
            limit: 100,
            null: false,
          },
          ProjectCommonName: {
            type: :string,
            limit: 50,
          },
          OperatingStartDate: {
            type: :date,
            null: false,
          },
          OperatingEndDate: {
            type: :date,
          },
          ContinuumProject: {
            type: :integer,
            null: false,
          },
          ProjectType: {
            type: :integer,
          },
          HousingType: {
            type: :integer,
          },
          ResidentialAffiliation: {
            type: :integer,
          },
          TrackingMethod: {
            type: :integer,
          },
          HMISParticipatingProject: {
            type: :integer,
            null: false,
          },
          TargetPopulation: {
            type: :integer,
          },
          HOPWAMedAssistedLivingFac: {
            type: :integer,
          },
          PITCount: {
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
        [:ProjectID] => nil,
        [:ProjectType] => nil,
        [:ExportID] => nil,
      }
    end
  end
end
