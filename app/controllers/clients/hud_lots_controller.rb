###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Logic from https://www.hudexchange.info/resource/5689/client-level-system-use-and-length-of-time-homeless-report/

class Clients::HudLotsController < ApplicationController
  include ClientPathGenerator
  include ClientDependentControllers

  before_action :require_can_see_this_client_demographics!
  before_action :set_client
  before_action :set_dates
  before_action :set_filter
  before_action :set_report
  after_action :log_client

  def index
  end

  private def set_client
    @client = destination_searchable_client_scope.find(params[:client_id].to_i)
  end

  private def set_report
    @report = GrdaWarehouse::WarehouseReports::HudLot.new(client: @client, filter: @filter)
  end

  private def title_for_show
    "#{@client.name} - Client-Level System Use & Length of Time Homeless Report"
  end
  helper_method :title_for_show

  private def set_filter
    @filter = ::Filters::DateRange.new(start: @start_date, end: @end_date)
  end

  private def set_dates
    @end_date = params.dig(:filter, :end)&.to_date || Date.current
    @start_date = @end_date - 3.years + 1.days
  end
end
