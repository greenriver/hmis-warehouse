###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::Export::HmisTwentyTwenty
  class Organization < GrdaWarehouse::Import::HmisTwentyTwenty::Organization
    include ::Export::HmisTwentyTwenty::Shared
    setup_hud_column_access( GrdaWarehouse::Hud::Organization.hud_csv_headers(version: '2020') )

    self.hud_key = :OrganizationID

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
        export: export
      )
    end

    def project_exits_for_organization project_scope
      project_scope.where(
        p_t[:OrganizationID].eq(self.class.arel_table[:OrganizationID]).
        and(p_t[:data_source_id].eq(self.class.arel_table[:data_source_id]))
      ).arel.exists
    end
  end
end