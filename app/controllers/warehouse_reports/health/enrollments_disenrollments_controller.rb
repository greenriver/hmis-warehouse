###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports::Health
  class EnrollmentsDisenrollmentsController < ApplicationController
    include WarehouseReportAuthorization
    before_action :require_can_administer_health!
    before_action :set_acos
    before_action :set_enrollment_reasons
    before_action :set_months

    def index
    end

    def create
      file = params.dig(:report, :file)
      if file.present?
        @enrollment_reasons = Health::EnrollmentReasons.create(
          file: file,
          content: file.read,
        )
      end

      if @acos.blank?
        flash[:error] = 'You must specify an ACO'
        render :index
      else
        @report = Health::EnrollmentDisenrollment.new(
          start_date: @start_date,
          end_date: @end_date,
          effective_date: @effective_date,
          aco_ids: @acos,
          enrollment_reasons: @enrollment_reasons.reasons,
        )
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

    def download
      reasons = Health::EnrollmentReasons.find(params[:id].to_i)
      send_data(reasons.content, filename: reasons.name)
    end

    def months_for_select
      @months_for_select ||= Date::MONTHNAMES.reject(&:blank?).each_with_index.map { |m, i| [m, i + 1] }.freeze
    end
    helper_method :months_for_select

    def available_acos
      @available_acos ||= Health::AccountableCareOrganization.active.where.not(e_d_file_prefix: [nil, ''])
    end
    helper_method :available_acos

    def set_acos
      @acos = params.dig(:report, :acos)&.reject(&:blank?)&.map(&:to_i) || []
    end

    def set_enrollment_reasons
      @enrollment_reasons = Health::EnrollmentReasons.last || Health::EnrollmentReasons.new
    end

    def set_months
      current_month = Date.current.month
      @start_month = params.dig(:report, :start_month)&.to_i || current_month
      @end_month = params.dig(:report, :end_month)&.to_i || current_month
      @effective_date = params.dig(:report, :effective_date)&.to_date || Date.current

      current_year = Date.current.year
      @start_date = if @start_month <= current_month
        Date.new(current_year, @start_month, 1)
      else
        Date.new(current_year - 1, @start_month, 1)
      end

      @end_date = if @end_month <= current_month
        Date.new(current_year, @end_month, 1)
      else
        Date.new(current_year - 1, @end_month, 1)
      end

      # Swap the dates if they are backwards
      @start_date, @end_date = @end_date, @start_date if @end_date < @start_date

      @end_date = @end_date.end_of_month
    end
  end
end
