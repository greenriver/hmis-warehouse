###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
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
      @filter.effective_project_ids_from_projects.presence || GrdaWarehouse::Hud::Project.viewable_by(current_user).pluck(:id)
    end

    private def set_filter
      @filter = if filter_params.present?
        ::Filters::DateRangeAndSources.new(filter_params)
      else
        ::Filters::DateRangeAndSources.new(start: '2020-03-18'.to_date, end: Date.current)
      end
    end

    private def filter_params
      return unless params[:filter].present?

      params.require(:filter).permit(
        :start,
        :end,
        project_ids: [],
      )
    end
    helper_method :filter_params

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
