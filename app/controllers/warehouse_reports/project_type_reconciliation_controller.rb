###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports
  class ProjectTypeReconciliationController < ApplicationController
    include ArelHelper
    include WarehouseReportAuthorization
    before_action :set_limited, only: [:index]

    def index
      @overrides = HmisCsvImporter::ImportOverride.where(file_name: 'Project.csv', replaces_column: 'ProjectType')
      overridden_ids = []
      @overrides.each do |o|
        if o.matched_hud_key.present?
          # Individual overrides
          overridden_ids += project_source.
            where(data_source_id: o.data_source_id, ProjectID: o.matched_hud_key).
            # where.not(ProjectType: o.replacement_value).
            pluck(:id)
        else
          # Blanket overrides (this should never happen)
          overridden_ids += project_source.
            where(data_source_id: o.data_source_id).
            # where.not(ProjectType: o.replacement_value).
            pluck(:id)
        end
      end
      @projects = if overridden_ids.any?
        project_source.
          joins(:organization, :data_source).
          where(id: overridden_ids).
          order(ds_t[:short_name].asc, o_t[:OrganizationName].asc, p_t[:ProjectName].asc)
      else
        project_source.none
      end
    end

    def project_source
      GrdaWarehouse::Hud::Project.viewable_by(current_user, permission: :can_view_assigned_reports)
    end
  end
end
