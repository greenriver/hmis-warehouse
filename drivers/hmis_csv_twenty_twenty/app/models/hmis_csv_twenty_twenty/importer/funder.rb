###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwenty::Importer
  class Funder < GrdaWarehouse::Hud::Base
    include ::HmisStructure::Funder
    include ImportConcern

    # Because GrdaWarehouse::Hud::* defines the table name, we can't use table_name_prefix :(
    self.table_name = 'hmis_2020_funders'

    has_one :destination_record, **hud_assoc(:FunderID, 'Funder')

    def self.involved_warehouse_scope(data_source_id:, project_ids:, date_range:) # rubocop:disable Lint/UnusedMethodArgument
      return none unless project_ids.present?

      warehouse_class.importable.joins(:project).
        merge(GrdaWarehouse::Hud::Project.where(data_source_id: data_source_id, ProjectID: project_ids))
    end

    def self.warehouse_class
      GrdaWarehouse::Hud::Funder
    end

    def self.hmis_validations
      {
        ProjectID: [
          class: HmisCsvValidation::NonBlank,
        ],
        Funder: [
          {
            class: HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HudUtility.funding_sources.keys.map(&:to_s).freeze },
          },
        ],
        GrantID: [
          class: HmisCsvValidation::NonBlankValidation,
        ],
        StartDate: [
          class: HmisCsvValidation::NonBlankValidation,
        ],
      }
    end
  end
end
