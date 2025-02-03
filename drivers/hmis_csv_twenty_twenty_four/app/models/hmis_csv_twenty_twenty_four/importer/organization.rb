###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyFour::Importer
  class Organization < GrdaWarehouse::Hud::Base
    include ::HmisStructure::Organization
    include ImportConcern

    # Because GrdaWarehouse::Hud::* defines the table name, we can't use table_name_prefix :(
    self.table_name = 'hmis_2024_organizations'

    has_one :destination_record, **hud_assoc(:OrganizationID, 'Organization')

    def self.involved_warehouse_scope(data_source_id:, project_ids:, date_range:) # rubocop:disable Lint/UnusedMethodArgument
      warehouse_class.importable.joins(:projects).
        merge(GrdaWarehouse::Hud::Project.where(data_source_id: data_source_id, ProjectID: project_ids))
    end

    def self.warehouse_class
      GrdaWarehouse::Hud::Organization
    end

    # Don't ever mark these for deletion
    def self.prevent_import_deletions?
      true
    end

    def self.hmis_validations
      {
        OrganizationID: [
          class: HmisCsvImporter::HmisCsvValidation::NonBlank,
        ],
        OrganizationName: [
          class: HmisCsvImporter::HmisCsvValidation::NonBlankValidation,
        ],
        VictimServiceProvider: [
          {
            class: HmisCsvImporter::HmisCsvValidation::NonBlankValidation,
          },
          {
            class: HmisCsvImporter::HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HudUtility2024.yes_no_missing_options.keys.map(&:to_s).freeze },
          },
        ],
      }
    end
  end
end
