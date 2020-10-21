###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports::Health
  class EnrollmentsDisenrollmentsController < ApplicationController
    include WarehouseReportAuthorization
    before_action :require_can_administer_health!
    before_action :set_acos
    before_action :set_month

    def index
    end

    def create
      if @acos.blank?
        flash[:error] = 'You must specify an ACO'
        render :index
      else
        @report = Health::EnrollmentDisenrollment.new(@month, @acos)
        summary = render_to_string 'summary.xlsx'
        report = render_to_string 'report.xlsx'
        stringio = Zip::OutputStream.write_buffer do |zio|
          zio.put_next_entry(@report.summary_file_name)
          zio.write(summary)

          zio.put_next_entry(@report.report_file_name)
          zio.write(report)
        end
        send_data(stringio.string, filename: @report.zip_file_name)
      end
    end

    def months
      @months ||= Date::MONTHNAMES.reject(&:blank?).each_with_index.map { |m, i| [m, i + 1] }.freeze
    end
    helper_method :months

    def available_acos
      @available_acos ||= Health::AccountableCareOrganization.where.not(e_d_file_prefix: nil)
    end
    helper_method :available_acos

    def set_acos
      @acos = params.dig(:report, :acos)&.reject(&:blank?)&.map(&:to_i) || []
    end

    def set_month
      @month = params.dig(:report, :month)&.to_i || Date.current.month
    end
  end
end
