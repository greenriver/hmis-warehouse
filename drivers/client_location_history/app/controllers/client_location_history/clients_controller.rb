###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClientLocationHistory
  class ClientsController < ApplicationController
    include ClientController
    include ClientPathGenerator
    before_action :require_can_view_clients!
    before_action :require_can_view_client_locations!
    before_action :set_client

    def map
      @locations = @client.client_location_histories.where(located_on: filter.range)
      @markers = @locations.map(&:as_marker)
      @bounds = ClientLocationHistory::Location.bounds(@locations)
      @markers = ClientLocationHistory::Location.highlight(@markers)
      @options = {
        bounds: @bounds,
        cluster: true,
        border_color: 'DarkBlue',
        highlight_color: 'ForestGreen',
      }
    end

    private def client_source
      ::GrdaWarehouse::Hud::Client
    end

    private def client_scope(id: nil)
      client_source.destination_visible_to(current_user).where(id: id)
    end

    private def filter
      @filter ||= filter_class.new(
        user_id: current_user.id,
        enforce_one_year_range: false,
      ).set_from_params(filter_params[:filters])
    end

    def filter_params
      opts = params
      opts[:filters] ||= {}
      opts[:filters][:enforce_one_year_range] = false
      opts[:filters][:start] ||= 6.years.ago
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
