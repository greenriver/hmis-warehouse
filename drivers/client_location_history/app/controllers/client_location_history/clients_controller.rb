###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClientLocationHistory
  class ClientsController < ApplicationController
    include ClientController
    include ClientPathGenerator
    include ClientDependentControllers

    before_action :require_can_view_clients!
    before_action :require_can_view_client_locations!
    before_action :set_client

    def map
      client_ids = [@client.id]
      # Include any source clients with a location, but make sure we only bring in those that are visible to the current user
      client_ids += ::GrdaWarehouse::Hud::Client.source_visible_to(current_user, client_ids: @client.source_client_ids).where(id: @client.source_client_ids).pluck(:id) if @client.destination?
      client_ids = client_ids.uniq
      @locations = ClientLocationHistory::Location.where(client_id: client_ids, located_on: filter.range)
      @markers = @locations.map(&:as_marker)
      @bounds = ClientLocationHistory::Location.bounds(@locations)
      @markers = ClientLocationHistory::Location.highlight(@markers)
      @options = {
        bounds: @bounds,
        cluster: true,
        marker_color: ClientLocationHistory::Location::MARKER_COLOR,
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
