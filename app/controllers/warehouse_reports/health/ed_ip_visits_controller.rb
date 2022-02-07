###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports::Health
  class EdIpVisitsController < ApplicationController
    before_action :require_can_administer_health!

    def index
      @files = file_scope
    end

    def show
      @file = file_scope.find(params[:id].to_i)
      @rows = @file.loaded_ed_ip_visits.page(params[:page]).per(25)
    end

    def create
      @file = Health::EdIpVisitFileV2.create(
        content: visit_params[:content].read,
        user: current_user,
        file: visit_params[:content].original_filename,
      )
      Health::EdIpImportJob.perform_later(@file.id)
      redirect_to warehouse_reports_health_ed_ip_visits_path
    rescue Exception => e
      flash[:error] = "Error processing uploaded file #{e}"
      redirect_to action: :index
    end

    def destroy
      file = file_scope.find(params[:id].to_i)
      # These files are sometimes huge, so batch delete visits
      file.loaded_ed_ip_visits.update_all(deleted_at: Time.current)
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
