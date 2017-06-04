module WarehouseReports
  class ProjectController < ApplicationController
    before_action :require_can_view_reports!

    def data_quality
      @projects = project_scope.includes(:organization, :data_source).
        group_by{ |m| [m.data_source.short_name, m.organization]}
    end


    def project_scope
      GrdaWarehouse::Hud::Project.all
    end
  end
end