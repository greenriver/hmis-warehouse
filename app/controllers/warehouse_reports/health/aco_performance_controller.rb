###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports::Health
  class AcoPerformanceController < ApplicationController
    include ArelHelper
    include WindowClientPathGenerator
    include WarehouseReportAuthorization

    before_action :require_can_view_aggregate_health!
    before_action :require_can_administer_health!
    before_action :set_aco, only: [:index]

    def index
      @report = Health::AcoPerformance.new(@aco) unless @aco.zero?
    end

    def set_aco
      @aco = params.dig(:filter, :aco).to_i
      @aco_name = Health::AccountableCareOrganization.find(@aco)&.name unless @aco.zero?
    end
  end
end
