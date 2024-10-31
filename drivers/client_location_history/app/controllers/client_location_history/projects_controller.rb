###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClientLocationHistory
  class ProjectsController < ApplicationController
    before_action :set_project
    before_action :require_can_view_projects!
    before_action :require_can_view_project_locations!

    def map
      @locations = @project.enrollment_location_histories.where(located_on: filter.range)
      @markers = @locations.map { |l| l.as_marker(current_user, [:name, :seen_on]) }
      @bounds = ClientLocationHistory::Location.bounds(@locations)
      @options = {
        bounds: @bounds,
        cluster: true,
        marker_color: ClientLocationHistory::Location::MARKER_COLOR,
      }
    end

    private def set_project
      @project = project_scope.includes(:enrollment_location_histories).find(params[:id].to_i)
    end

    private def project_source
      ::GrdaWarehouse::Hud::Project
    end

    private def project_scope
      project_source.
        viewable_by(current_user, confidential_scope_limiter: :all, permission: :can_view_projects).
        viewable_by(current_user, permission: :can_view_project_locations)
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
      opts[:filters][:start] ||= 1.year.ago
      opts[:filters][:end] ||= Date.current
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
