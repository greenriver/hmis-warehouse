###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReportsHealthEmergencyController
  extend ActiveSupport::Concern

  included do
    before_action :require_health_emergency!
    before_action :set_filter

    def require_health_emergency!
      return true if health_emergency?

      not_authorized!
    end

    private def project_ids
      # NOTE: 12/11 request to remove viewable_by limit
      # @filter.effective_project_ids_from_projects.presence || GrdaWarehouse::Hud::Project.viewable_by(current_user).pluck(:id)
      @filter.effective_project_ids_from_projects.presence || GrdaWarehouse::Hud::Project.pluck(:id)
    end

    private def set_filter
      clean_params = filter_params || {}
      @filter = if filter_params&.dig(:start).present?
        ::Filters::DateRangeAndSources.new(filter_params)
      else
        ::Filters::DateRangeAndSources.new(clean_params.merge(start: default_start_date, end: Date.current))
      end
    end

    private def default_start_date
      '2020-03-18'.to_date
    end

    private def filter_params
      return unless params[:filter].present?

      params.require(:filter).permit(
        :start,
        :end,
        :sort,
        project_ids: [],
      )
    end
    helper_method :filter_params

    private def selected_sort
      sort_options.keys.detect { |m| m == params.dig(:filter, :sort)&.to_sym } || sort_options.keys.first
    end

    private def available_locations
      GrdaWarehouse::Hud::Project.viewable_by(current_user).map do |p|
        [
          p.name_and_type,
          p.id,
        ]
      end
    end
    helper_method :available_locations
  end
end
