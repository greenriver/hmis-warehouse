###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HealthFlexibleService::WarehouseReports
  class MemberListsController < ApplicationController
    include WarehouseReportAuthorization
    before_action :require_can_administer_health!
    before_action :set_parameters

    def index
    end

    def create
      member_list = HealthFlexibleService::MemberList.new(@aco, @r_number, @end_date)
      xlsx = member_list.write_to('drivers/health_flexible_service/app/views/health_flexible_service/warehouse_reports/member_lists/template.xlsm')
      send_data(xlsx.stream.string, filename: member_list.filename)
    end

    def set_parameters
      @aco = report_parameters[:aco]&.to_i
      @r_number = report_parameters[:r_number]&.to_i
      @end_date = report_parameters[:date]&.to_date || Date.current.end_of_month
    end

    def report_parameters
      return {} unless params[:report]

      params.require(:report).
        permit(
          :aco,
          :r_number,
          :date,
        )
    end

    def available_acos
      Health::AccountableCareOrganization.where.not(vpr_name: nil).order(:name)
    end
    helper_method :available_acos

    def r_numbers
      @r_numbers ||= {
        'Initial Submission (R0)' => 0,
        'Initial Revision (R1)' => 1,
        'Submission (R2)' => 2,
        'Submission (R3)' => 3,
      }.freeze
    end
    helper_method :r_numbers
  end
end
