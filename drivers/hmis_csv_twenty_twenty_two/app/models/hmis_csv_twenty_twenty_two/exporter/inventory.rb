###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyTwo::Exporter
  class Inventory
    include ::HmisCsvTwentyTwentyTwo::Exporter::ExportConcern

    def initialize(options)
      @options = options
    end

    def process(row)
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

      export_scope.preload(:user, :project)
    end

    def self.transforms
      [
        HmisCsvTwentyTwentyTwo::Exporter::Inventory::Overrides,
        HmisCsvTwentyTwentyTwo::Exporter::FakeData,
        HmisCsvTwentyTwentyTwo::Exporter::Inventory,
      ]
    end
  end
end
