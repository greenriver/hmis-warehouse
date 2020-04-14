###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module WarehouseReports::HealthEmergency
  class UploadedResultsController < ApplicationController
    include ArelHelper
    include PjaxModalController
    include WarehouseReportAuthorization
    include WarehouseReportsHealthEmergencyController
    before_action :require_can_edit_health_emergency_clinical!

    def index
      @results = upload_scope.
        page(params[:page]).
        per(25)
    end

    def new
      @upload = upload_source.new
    end

    def create
      @upload = upload_source.create(upload_params.merge(user_id: current_user.id))
      @upload.delay.process!
      respond_with(@upload, location: warehouse_reports_health_emergency_uploaded_results_path)
    end

    def upload_params
      params.require(:upload).
        permit(
          :file,
        )
    end

    private def upload_source
      GrdaWarehouse::HealthEmergency::TestBatch
    end

    private def upload_scope
      upload_source.visible_to(current_user).newest_first
    end

    def flash_interpolation_options
      { resource_name: 'Testing Results Batch' }
    end
  end
end
