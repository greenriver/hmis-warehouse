###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwenty::Importer
  class ProjectCoc < GrdaWarehouse::Hud::Base
    include ::HMIS::Structure::ProjectCoc
    include ImportConcern

    # Because GrdaWarehouse::Hud::* defines the table name, we can't use table_name_prefix :(
    self.table_name = 'hmis_2020_project_cocs'

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
          class: HmisCsvValidation::NonBlank,
        ],
        CoCCode: [
          {
            class: HmisCsvValidation::NonBlank,
          },
          {
            class: HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HUD.cocs.keys.freeze },
          },
        ],
        Geocode: [
          {
            class: HmisCsvValidation::NonBlankValidation,
          },
          {
            class: HmisCsvValidation::ValidFormat,
            arguments: { regex: /^[0-9]{6}$/ },
          },
        ],
        State: [
          {
            class: HmisCsvValidation::ValidFormat,
            arguments: { regex: /^[a-zA-Z]{2}$/ },
          },
        ],
        Zip: [
          {
            class: HmisCsvValidation::ValidFormat,
            arguments: { regex: /^[0-9]{5}$/ },
          },
        ],
      }
    end
  end
end
