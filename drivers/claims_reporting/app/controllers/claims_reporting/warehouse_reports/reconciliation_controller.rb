###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
module ClaimsReporting::WarehouseReports
  class ReconciliationController < ApplicationController
    include WarehouseReportAuthorization
    before_action :require_can_view_member_health_reports!

    # include AjaxModalRails::Controller
    include ArelHelper
    # include BaseFilters

    # before_action :set_report
    def index
      @upload = ClaimsReporting::CpPaymentUpload.new
    end

    def create
      if params[:file]
        upload = params.dig(:file, :content)
        @upload = ClaimsReporting::CpPaymentUpload.new(
          user_id: current_user.id,
          content: upload.read,
          original_filename: upload.original_filename,
        )
        if @upload.save
          @upload.process!
          flash[:notice] = 'Upload accepted and processed successfully'
        else
          flash[:notice] = @upload.errors.full_messages.to_sentence
        end
      end
      redirect_to request.referrer || url_for(action: :index)
    end
  end
end
