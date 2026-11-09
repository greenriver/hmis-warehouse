###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Filters
  # Resolves a project group's saved options into its project list, against every project
  # rather than the ones a user can see.
  #
  # The options were submitted by a group editor and are not limited to projects that editor
  # can see; that's an accepted risk. Build it only through `for_project_group`, so it is never
  # given request params or any options other than a saved group's.
  #
  # Confidential projects are kept when picked by name, and left out of organization, data
  # source, and project type selections, as the project group form tells editors.
  class SystemProjectHudFilter < HudFilterBase
    private_class_method :new

    def self.for_project_group(project_group)
      filter = new(user_id: User.setup_system_user.id).update(project_group.options)
      filter.coc_codes = []
      filter
    end

    def all_project_scope
      GrdaWarehouse::Hud::Project.non_confidential
    end

    def criteria_project_scope
      GrdaWarehouse::Hud::Project.all
    end

    def effective_project_ids_from_projects
      @effective_project_ids_from_projects ||= begin
        submitted_ids = project_ids.map(&:to_i)
        submitted_ids.empty? ? [] : GrdaWarehouse::Hud::Project.where(id: submitted_ids).pluck(:id)
      end
    end

    # A new project group isn't visible to the system user until system group maintenance runs
    private def viewable_project_group_scope
      GrdaWarehouse::ProjectGroup.all
    end
  end
end
