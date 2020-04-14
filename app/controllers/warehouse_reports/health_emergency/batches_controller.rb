###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module WarehouseReports::HealthEmergency
  class BatchesController < ApplicationController
    include ArelHelper
    include PjaxModalController
    include WarehouseReportsHealthEmergencyController
    before_action :require_can_edit_health_emergency_clinical!

    def index
      @batch = upload_scope.find(params[:uploaded_result_id].to_i)
      @results = @batch.uploaded_tests
    end

    private def upload_source
      GrdaWarehouse::HealthEmergency::TestBatch
    end

    private def upload_scope
      upload_source.visible_to(current_user).newest_first
    end
  end
end
