###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module WarehouseReports::Health
  class EdIpVisitsController < ApplicationController
    before_action :require_can_administer_health!

    def index
      @files = file_scope
    end

    def show
      @file = file_scope.find(params[:id].to_i)
      @rows = @file.ed_ip_visits.page(params[:page]).per(25)
    end

    def create
      @file = Health::EdIpVisitFile.create(
        content: visit_params[:content].read,
        user: current_user,
        file: visit_params[:content].original_filename,
      )
      @file.create_visits!
      redirect_to warehouse_reports_health_ed_ip_visit_path(@file)
    rescue Exception => e
      flash[:error] = "Error processing uploaded file #{e}"
      redirect_to action: :index
    end

    def destroy
      file = file_scope.find(params[:id].to_i)
      file.destroy
      redirect_to action: :index
    end

    def visit_params
      params.require(:visits).permit(:content)
    end

    private def file_scope
      Health::EdIpVisitFile.order(created_at: :desc)
    end
  end
end
