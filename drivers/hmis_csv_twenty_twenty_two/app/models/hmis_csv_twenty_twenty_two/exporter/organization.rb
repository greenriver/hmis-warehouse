###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyTwo::Exporter
  class Organization < GrdaWarehouse::Hud::Organization
    include ::HmisCsvTwentyTwentyTwo::Exporter::Shared
    setup_hud_column_access(GrdaWarehouse::Hud::Organization.hud_csv_headers(version: '2022'))

    has_many :projects_with_deleted, class_name: 'GrdaWarehouse::Hud::WithDeleted::Project', primary_key: [:OrganizationID, :data_source_id], foreign_key: [:OrganizationID, :data_source_id], inverse_of: :organization

    def export! project_scope:, path:, export:
      case export.period_type
      when 3
        export_scope = self.class.where(project_exits_for_organization(project_scope))
      when 1
        export_scope = self.class.where(project_exits_for_organization(project_scope)).modified_within_range(range: (export.start_date..export.end_date))
      end
      export_to_path(
        export_scope: export_scope,
        path: path,
        export: export,
      )
    end

    def project_exits_for_organization project_scope
      project_scope.where(
        p_t[:OrganizationID].eq(self.class.arel_table[:OrganizationID]).
        and(p_t[:data_source_id].eq(self.class.arel_table[:data_source_id])),
      ).arel.exists
    end

    def apply_overrides(row, data_source_id:) # rubocop:disable Lint/UnusedMethodArgument
      row[:VictimServiceProvider] = 99 if row[:VictimServiceProvider].blank?
      row[:UserID] = 'op-system' if row[:UserID].blank?

      row
    end
  end
end
