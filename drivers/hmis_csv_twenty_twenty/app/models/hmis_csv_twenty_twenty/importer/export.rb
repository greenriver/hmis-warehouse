###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwenty::Importer
  class Export < GrdaWarehouse::Hud::Base
    include ::HMIS::Structure::Export
    include ImportConcern

    # Because GrdaWarehouse::Hud::* defines the table name, we can't use table_name_prefix :(
    self.table_name = 'hmis_2020_exports'

    has_one :destination_record, **hud_assoc(:ExportID, 'Export')

    def self.involved_warehouse_scope(data_source_id:, project_ids:, date_range:) # rubocop:disable Lint/UnusedMethodArgument
      warehouse_class.importable.where(data_source_id: data_source_id)
    end

    def self.warehouse_class
      GrdaWarehouse::Hud::Export
    end

    # Don't ever mark these for deletion
    def self.mark_tree_as_dead(data_source_id:, project_ids:, date_range:, pending_date_deleted:, importer_log_id:)
    end

    def self.hmis_validations
      {
        ExportID: [
          class: HmisCsvValidation::NonBlank,
        ],
        SourceType: [
          {
            class: HmisCsvValidation::NonBlankValidation,
          },
          {
            class: HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HUD.source_types.keys.map(&:to_s).freeze },
          },
        ],
        ExportStartDate: [
          class: HmisCsvValidation::NonBlank,
        ],
        ExportEndDate: [
          class: HmisCsvValidation::NonBlank,
        ],
        ExportPeriodType: [
          {
            class: HmisCsvValidation::NonBlankValidation,
          },
          {
            class: HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HUD.period_types.keys.map(&:to_s).freeze },
          },
        ],
        ExportDirective: [
          {
            class: HmisCsvValidation::NonBlankValidation,
          },
          {
            class: HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HUD.export_directives.keys.map(&:to_s).freeze },
          },
        ],
        HashStatus: [
          {
            class: HmisCsvValidation::NonBlankValidation,
          },
          {
            class: HmisCsvValidation::InclusionInSet,
            arguments: { valid_options: HUD.hash_statuses.keys.map(&:to_s).freeze },
          },
        ],
      }
    end
  end
end
