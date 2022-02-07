###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyTwo::Importer
  class Inventory < GrdaWarehouse::Hud::Base
    include ::HMIS::Structure::Inventory
    include ImportConcern

    # Because GrdaWarehouse::Hud::* defines the table name, we can't use table_name_prefix :(
    self.table_name = 'hmis_2022_inventories'

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
          class: HmisCsvImporter::HmisCsvValidation::NonBlank,
        ],
        CoCCode: [
          {
            class: HmisCsvImporter::HmisCsvValidation::NonBlankValidation,
          },
          {
            class: HmisCsvImporter::HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HUD.cocs.keys.freeze },
          },
        ],
        HouseholdType: [
          {
            class: HmisCsvImporter::HmisCsvValidation::NonBlankValidation,
          },
          {
            class: HmisCsvImporter::HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HUD.household_types.keys.map(&:to_s).freeze },
          },
        ],
        Availability: [
          {
            class: HmisCsvImporter::HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HUD.availabilities.keys.map(&:to_s).freeze },
          },
        ],
        UnitInventory: [
          class: HmisCsvImporter::HmisCsvValidation::NonBlankValidation,
        ],
        BedInventory: [
          class: HmisCsvImporter::HmisCsvValidation::NonBlankValidation,
        ],
        InventoryStartDate: [
          class: HmisCsvImporter::HmisCsvValidation::NonBlankValidation,
        ],
      }
    end
  end
end
