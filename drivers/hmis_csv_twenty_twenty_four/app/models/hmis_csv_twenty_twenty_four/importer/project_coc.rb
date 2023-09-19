###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyFour::Importer
  class ProjectCoc < GrdaWarehouse::Hud::Base
    include ::HmisStructure::ProjectCoc
    include ImportConcern

    # Because GrdaWarehouse::Hud::* defines the table name, we can't use table_name_prefix :(
    self.table_name = 'hmis_2024_project_cocs'

    has_one :destination_record, **hud_assoc(:ProjectCoCID, 'ProjectCoc')

    def self.involved_warehouse_scope(data_source_id:, project_ids:, date_range:) # rubocop:disable Lint/UnusedMethodArgument
      return none unless project_ids.present?

      warehouse_class.importable.joins(:project).
        merge(GrdaWarehouse::Hud::Project.where(data_source_id: data_source_id, ProjectID: project_ids))
    end

    def self.warehouse_class
      GrdaWarehouse::Hud::ProjectCoc
    end

    def self.hmis_validations
      {
        ProjectID: [
          class: HmisCsvImporter::HmisCsvValidation::NonBlank,
        ],
        CoCCode: [
          {
            class: HmisCsvImporter::HmisCsvValidation::NonBlank,
          },
          {
            class: HmisCsvImporter::HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HudUtility2024.cocs.keys.freeze },
          },
        ],
        Geocode: [
          {
            class: HmisCsvImporter::HmisCsvValidation::NonBlankValidation,
          },
          {
            class: HmisCsvImporter::HmisCsvValidation::ValidFormat,
            arguments: { regex: /^[0-9]{6}$/ },
          },
        ],
        State: [
          {
            class: HmisCsvImporter::HmisCsvValidation::ValidFormat,
            arguments: { regex: /^[a-zA-Z]{2}$/ },
          },
        ],
        Zip: [
          {
            class: HmisCsvImporter::HmisCsvValidation::ValidFormat,
            arguments: { regex: /^[0-9]{5}$/ },
          },
        ],
      }
    end
  end
end
