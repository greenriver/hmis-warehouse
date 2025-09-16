###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvTwentyTwentySix::Exporter
  class Inventory
    include ::HmisCsvTwentyTwentySix::Exporter::ExportConcern

    def initialize(options)
      @options = options
    end

    def self.adjust_keys(row, _export)
      row.UserID = row.user&.id || 'op-system'
      row.ProjectID = row.project&.id || 'Unknown'
      row.InventoryID = row.id

      row
    end

    def self.export_scope(project_scope:, export:, hmis_class:, **_)
      export_scope = case export.period_type
      when 3
        hmis_class.where(project_exists_for_model(project_scope, hmis_class))
      when 1
        hmis_class.where(project_exists_for_model(project_scope, hmis_class)).
          modified_within_range(range: (export.start_date..export.end_date))
      end
      note_involved_user_ids(scope: export_scope, export: export)

      # Limit to the chosen CoC codes if any are specified
      filter = export.filter
      export_scope = export_scope.where(CoCCode: filter.coc_codes) if filter.coc_codes.any?

      # Limit to the chosen date range if the option is enabled
      export_scope = export_scope.within_range(export.start_date..export.end_date) if filter.enforce_project_date_scope

      export_scope.distinct.preload(:user, :project)
    end

    def self.transforms
      [
        HmisCsvTwentyTwentySix::Exporter::Inventory::Overrides,
        HmisCsvTwentyTwentySix::Exporter::Inventory,
        HmisCsvTwentyTwentySix::Exporter::FakeData,
      ]
    end
  end
end
