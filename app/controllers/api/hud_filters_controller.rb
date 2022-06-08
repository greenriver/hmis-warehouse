###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
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
        projects = GrdaWarehouse::Hud::Project.
          joins(:organization).
          where(id: filter.effective_project_ids)

        projects = projects.with_hud_project_type(params[:supported_project_types].map(&:to_i)) if params[:supported_project_types].present?

        projects.pluck(
          :id,
          :ProjectName,
          :confidential,
          :computed_project_type,
          o_t[:OrganizationName],
          o_t[:id],
        ).each do |id, p_name, p_confidential, type, o_name, o_id|
          name = GrdaWarehouse::Hud::Project.confidentialize_name(current_user, p_name, p_confidential)
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
