###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

require 'rubyXL'

module HealthFlexibleService::WarehouseReports
  class MemberListsController < ApplicationController
    include WarehouseReportAuthorization
    before_action :require_can_administer_health!
    before_action :set_parameters

    def index
    end

    def create
      member_list = HealthFlexibleService::MemberList.new(@aco, @r_number, @end_date)
      xlsx = RubyXL::Parser.parse('drivers/health_flexible_service/app/views/health_flexible_service/warehouse_reports/member_lists/template.xlsx')
      member_list.write_to(xlsx)
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
      Health::AccountableCareOrganization.where.not(vpr_name: nil)
    end
    helper_method :available_acos
  end
end
