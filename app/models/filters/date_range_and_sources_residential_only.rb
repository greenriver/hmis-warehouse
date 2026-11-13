###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Filters
  class DateRangeAndSourcesResidentialOnly < FilterBase
    def all_project_scope
      GrdaWarehouse::Hud::Project.residential.viewable_by(user)
    end

    # Only individually picked projects bypass the residential limit: they keep any project
    # type the user can report on. The "Any" default and organization and data source picks
    # still use the residential `all_project_scope`
    def effective_project_ids_from_projects
      @effective_project_ids_from_projects ||= begin
        submitted_ids = project_ids.reject(&:blank?).map(&:to_i)
        submitted_ids.empty? ? [] : picked_project_scope.where(id: submitted_ids).pluck(:id)
      end
    end

    private def picked_project_scope
      GrdaWarehouse::Hud::Project.viewable_by(user, permission: :can_view_assigned_reports)
    end
  end
end
