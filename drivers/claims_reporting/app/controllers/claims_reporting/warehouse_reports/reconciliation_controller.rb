###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
module ClaimsReporting::WarehouseReports
  class ReconciliationController < ApplicationController
    include WarehouseReportAuthorization
    # before_action :require_can_view_member_health_reports!

    # include AjaxModalRails::Controller
    include ArelHelper
    # include BaseFilters

    # before_action :set_report
    def index
      dates = if ::Health::Claim.none?
        ::Health::QualifyingActivity.distinct.pluck(:date_of_activity)
      else
        ::Health::Claim.distinct.pluck(:max_date)
      end

      @available_months = dates.map(&:beginning_of_month).sort.uniq.reverse

      month = begin
                Date.parse(filter_params[:month]).beginning_of_month
              rescue StandardError
                nil
              end
      @active_month = @available_months.detect { |m| m == month } || @available_months.first
    end

    def create
      if params[:file]
        upload = params.dig(:file, :content)
        record = ClaimsReporting::CpPaymentUpload.new(
          user_id: current_user.id,
          content: upload.read,
          original_filename: upload.original_filename,
        )
        if @upload.save
          record.process!
          flash[:notice] = 'Upload accepted and processed successfully'
        else
          flash[:notice] = record.errors.full_messages.to_sentence
        end
      end
      redirect_to request.referrer || url_for(action: :index)
    end

    private def filter_params
      params.fetch(:filter, {}).permit(
        :month,
        acos: [],
      )
    end
  end
end
