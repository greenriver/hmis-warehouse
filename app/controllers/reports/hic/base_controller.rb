###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Reports
  class Hic::BaseController < ApplicationController
    before_action :require_can_view_hud_reports!
    before_action :set_filter
    # ES (1), TH (2), SH (8), PSH (3), RRH (13), PH (10), PH (9)
    PROJECT_TYPES = [1, 2, 3, 8, 9, 10, 13].freeze

    private def set_filter
      @filter = if params[:filters].present?
        ::Filters::FilterBase.new(user_id: current_user.id).set_from_params(export_params)
      else
        current_year = Date.current.year
        last_wednesday_of_january = if Date.current >= Date.new(current_year, 2, 1)
          Date.new(current_year, 2, 1).prev_occurring(:wednesday)
        else
          Date.new(current_year - 1, 2, 1).prev_occurring(:wednesday)
        end
        ::Filters::FilterBase.new(user_id: current_user.id, on: last_wednesday_of_january)
      end
    end

    private def export_params
      params.require(:filters).
        permit(
          :version,
          :on,
          coc_codes: [],
          data_source_ids: [],
          project_ids: [],
          project_group_ids: [],
        )
    end

    private def project_scope
      scope = GrdaWarehouse::Hud::Project.active_on(@filter.on).
        viewable_by(current_user).
        with_hud_project_type(PROJECT_TYPES)
      project_ids = @filter.anded_effective_project_ids
      scope = scope.where(id: project_ids) if project_ids.present?
      scope
    end
  end
end
