module WarehouseReports
  class RrhController < ApplicationController
    include WarehouseReportAuthorization

    respond_to :html, :js

    def index
      
    end

    def program_data
      
    end

    private def project_source
      GrdaWarehouse::Hud::Project.viewable_by(current_user)
    end

    private def housed_source
      Reporting::Housed.where(project_type: 13).viewable_by(current_user)
    end

    private def returns_source
      Reporting::Return
    end

  end
end
