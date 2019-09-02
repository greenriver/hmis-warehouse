###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::Export::HMIS2020
  class User < GrdaWarehouse::Import::HMIS2020::User
    include ::Export::HMIS2020::Shared
    setup_hud_column_access( GrdaWarehouse::Hud::User.hud_csv_headers(version: '2020') )

    self.hud_key = :UserID

    def export! project_scope:, path:, export:
      raise 'TODO'
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


  end
end