###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClientLocationHistory::WarehouseReports
  class ClientLocationHistoryController < ApplicationController
    include WarehouseReportAuthorization
    include AjaxModalRails::Controller
    include ArelHelper
    include BaseFilters

    before_action :filter

    def index
      ids = ClientLocationHistory::Location.joins(:client).
        merge(GrdaWarehouse::Hud::Client.destination_visible_to(current_user)).
        where(located_on: filter.range).
        order(:client_id, located_on: :desc).
        distinct_on(:client_id).pluck(:id)
      @contacts = ClientLocationHistory::Location.where(id: ids).preload(:client)
      @markers = @contacts.map { |c| c.as_marker_with_name(current_user) }
      @bounds = ClientLocationHistory::Location.bounds(@contacts)
      @markers = ClientLocationHistory::Location.highlight(@markers)
      @options = {
        bounds: @bounds,
        cluster: true,
        border_color: 'DarkBlue',
        highlight_color: 'DarkBlue',
        link: true,
      }
    end

    private def filter
      @filter ||= filter_class.new(user_id: current_user.id).set_from_params(filter_params[:filters])
    end

    def filter_params
      opts = params
      opts[:filters] ||= {}
      opts[:filters][:start] ||= 6.months.ago
      opts[:filters][:end] ||= 1.days.ago
      opts.permit(
        filters: [
          :start,
          :end,
        ],
      )
    end
    helper_method :filter_params

    private def filter_class
      ::Filters::FilterBase
    end
  end
end
