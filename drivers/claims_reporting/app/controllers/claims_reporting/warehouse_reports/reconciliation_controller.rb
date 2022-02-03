###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClaimsReporting::WarehouseReports
  class ReconciliationController < ApplicationController
    include WarehouseReportAuthorization
    before_action :require_can_view_member_health_reports!

    def index
      @report = ClaimsReporting::ReconcilationReport.new(**filter_params)
      @file = ::ClaimsReporting::CpPaymentUpload.new
      export_name = "unmatched-claims-for-#{@report.month.end_of_month.to_s(:number)}"
      respond_to do |format|
        format.html {} # render the default template
        format.xlsx do
          render xlsx: 'index', filename: "#{export_name}.xlsx"
        end
        format.csv do
          send_data @report.to_csv, filename: "#{export_name}.csv"
        end
      end
    end

    private def available_months
      @available_months ||= begin
        dates = if ::Health::Claim.none?
          ::Health::QualifyingActivity.distinct.pluck(:date_of_activity)
        else
          ::Health::Claim.distinct.pluck(:max_date)
        end
        dates.map(&:beginning_of_month).sort.uniq.reverse
      end
    end
    helper_method :available_months

    def create
      if params[:file]
        upload = params.dig(:file, :content)
        record = ClaimsReporting::CpPaymentUpload.new(
          user_id: current_user.id,
          content: upload.read,
          original_filename: upload.original_filename,
        )
        if record.save
          record.process!
          flash[:notice] = 'Upload accepted and processed successfully'
        else
          flash[:notice] = record.errors.full_messages.to_sentence
        end
      end
      redirect_to request.referrer || url_for(action: :index)
    end

    private def filter_params
      params.fetch(:f, {}).permit(
        :month,
        aco_ids: [],
      ).tap do |filter|
        filter[:month] = available_months.detect { |m| m.iso8601 == filter[:month] } || available_months.first
      end.to_h.symbolize_keys
    end
  end
end
