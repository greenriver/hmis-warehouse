module WarehouseReports
  class RrhController < ApplicationController
    include WarehouseReportAuthorization

    respond_to :html, :js

    def index
      @program_1_id = housed_source.where(id: params[:program_1_id]).pluck(:id)&.first || nil
      @program_2_id = housed_source.where(id: params[:program_2_id]).pluck(:id)&.first || nil
      @programs_for_select = Reporting::D3Charts.programs_for_select(current_user)
    end

    def program_data
      respond_to do |format|
        format.js do
          @program_1_id = project_source.where(id: params[:program_1_id]).pluck(:id)&.first || nil
          @program_2_id = project_source.where(id: params[:program_2_id]).pluck(:id)&.first || nil
          @charts = Reporting::D3Charts.new(current_user, @program_1_id, @program_2_id)
        end
      end
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
