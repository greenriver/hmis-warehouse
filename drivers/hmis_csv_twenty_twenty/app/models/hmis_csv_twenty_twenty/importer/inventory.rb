###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwenty::Importer
  class Inventory < GrdaWarehouse::Hud::Base
    include ::HMIS::Structure::Inventory
    include ImportConcern

    # Because GrdaWarehouse::Hud::* defines the table name, we can't use table_name_prefix :(
    self.table_name = 'hmis_2020_inventories'

    has_one :destination_record, **hud_assoc(:InventoryID, 'Inventory')

    def self.involved_warehouse_scope(data_source_id:, project_ids:, date_range:) # rubocop:disable Lint/UnusedMethodArgument
      return none unless project_ids.present?

      warehouse_class.importable.joins(:project).
        merge(GrdaWarehouse::Hud::Project.where(data_source_id: data_source_id, ProjectID: project_ids))
    end

    def self.warehouse_class
      GrdaWarehouse::Hud::Inventory
    end

    def self.hmis_validations
      {
        ProjectID: [
          class: HmisCsvValidation::NonBlank,
        ],
        CoCCode: [
          {
            class: HmisCsvValidation::NonBlankValidation,
          },
          {
            class: HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HUD.cocs.keys.freeze },
          },
        ],
        HouseholdType: [
          {
            class: HmisCsvValidation::NonBlankValidation,
          },
          {
            class: HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HUD.household_types.keys.map(&:to_s).freeze },
          },
        ],
        Availability: [
          {
            class: HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HUD.availabilities.keys.map(&:to_s).freeze },
          },
        ],
        UnitInventory: [
          class: HmisCsvValidation::NonBlankValidation,
        ],
        BedInventory: [
          class: HmisCsvValidation::NonBlankValidation,
        ],
        InventoryStartDate: [
          class: HmisCsvValidation::NonBlankValidation,
        ],
      }
    end
  end
end
