###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports::Health
  class PremiumPaymentsController < ApplicationController
    include WarehouseReportAuthorization
    before_action :require_can_administer_health!

    def index
      @file = premium_source.new
      @files = premium_source.order(id: :desc).
        page(params[:page]).per(25)
    end

    def show
      @file = premium_source.find(params[:id].to_i)
      respond_to do |format|
        format.text do
          send_data @file.content, filename: "#{@file.original_filename}.txt", type: 'text/plain', disposition: :attachment
        end
        format.xlsx do
          response.headers['Content-Disposition'] = "attachment; filename=\"#{@file.original_filename}.xlsx\""
        end
      end
    end

    def create
      @file = premium_source.create(
        user_id: current_user.id,
        content: premium_params[:content].read,
        original_filename: premium_params[:content].original_filename,
      )
      Health::ConvertPaymentPremiumFileJob.perform_later
      respond_with(@file, location: warehouse_reports_health_premium_payments_path)
    end

    def premium_source
      Health::PremiumPayment
    end

    def premium_params
      params.require(:health_premium_payment).permit(:content)
    end

    def flash_interpolation_options
      { resource_name: 'Premium Payment File (820)' }
    end
  end
end
