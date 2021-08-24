###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HMIS::Structure::Inventory
  extend ActiveSupport::Concern
  include ::HMIS::Structure::Base

  included do
    self.hud_key = :InventoryID
    acts_as_paranoid(column: :DateDeleted)
  end

  module ClassMethods
    def hmis_configuration(version: nil)
      case version
      when '5.1', '6.11', '6.12'
        {
          InventoryID: {
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
          InformationDate: {
            type: :date,
          },
          HouseholdType: {
            type: :integer,
            null: false,
          },
          Availability: {
            type: :integer,
          },
          UnitInventory: {
            type: :integer,
            null: false,
          },
          BedInventory: {
            type: :integer,
            null: false,
          },
          CHBedInventory: {
            type: :integer,
          },
          VetBedInventory: {
            type: :integer,
          },
          YouthBedInventory: {
            type: :integer,
          },
          BedType: {
            type: :integer,
          },
          InventoryStartDate: {
            type: :date,
          },
          InventoryEndDate: {
            type: :date,
          },
          HMISParticipatingBeds: {
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
      when '2020', '2022', nil
        {
          InventoryID: {
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
          HouseholdType: {
            type: :integer,
            null: false,
          },
          Availability: {
            type: :integer,
          },
          UnitInventory: {
            type: :integer,
            null: false,
          },
          BedInventory: {
            type: :integer,
            null: false,
          },
          CHVetBedInventory: {
            type: :integer,
          },
          YouthVetBedInventory: {
            type: :integer,
          },
          VetBedInventory: {
            type: :integer,
          },
          CHYouthBedInventory: {
            type: :integer,
          },
          YouthBedInventory: {
            type: :integer,
          },
          CHBedInventory: {
            type: :integer,
          },
          OtherBedInventory: {
            type: :integer,
          },
          ESBedType: {
            type: :integer,
          },
          InventoryStartDate: {
            type: :date,
          },
          InventoryEndDate: {
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
        [:ProjectID, :CoCCode] => nil,
        [:InventoryID] => nil,
        [:ExportID] => nil,
      }
    end
  end
end
