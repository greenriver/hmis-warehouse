###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Provides a list of projects that belong to to the selected
# data sources and organizations
# optionally, limits the list to only those a user can see
# Default to all
module Api
  class HudFiltersController < ApplicationController
    include ArelHelper

    def index
      filter = ::Filters::HudFilterBase.new(user_id: current_user.id)
      filter.update(filter_params)
      respond_to do |format|
        @data = {}
        GrdaWarehouse::Hud::Project.
          joins(:organization).
          where(id: filter.effective_project_ids).
          pluck(
            :id,
            :ProjectName,
            :computed_project_type,
            o_t[:OrganizationName],
            o_t[:id],
          ).each do |id, p_name, type, o_name, o_id|
            name = GrdaWarehouse::Hud::Project.confidentialize(name: p_name)
            name = p_name if can_view_confidential_enrollment_details?
            @data[[o_id, o_name]] ||= []
            @data[[o_id, o_name]] << [
              "#{name} (#{HUD.project_type_brief(type)})",
              id,
            ]
          end
        format.html do
          render layout: false
        end
      end
    end

    def filter_params
      params.permit(::Filters::HudFilterBase.new(user_id: current_user.id).known_params)
    end
  end
end
