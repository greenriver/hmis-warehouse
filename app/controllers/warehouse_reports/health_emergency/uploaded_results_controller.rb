###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports::HealthEmergency
  class UploadedResultsController < ApplicationController
    include ArelHelper
    include AjaxModalRails::Controller
    include WarehouseReportAuthorization
    include WarehouseReportsHealthEmergencyController
    before_action :require_can_edit_health_emergency_clinical!

    def index
      @pagy, @results = pagy(upload_scope)
    end

    def new
      @upload = upload_source.new
    end

    def show
      @batch = upload_scope.find(params[:id].to_i)
      @results = @batch.uploaded_tests
    end

    def create
      file = upload_params[:file]
      @upload = upload_source.create(upload_params.merge(user_id: current_user.id, content: file.read))
      Importing::TestBatchUploadJob.perform_later
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
