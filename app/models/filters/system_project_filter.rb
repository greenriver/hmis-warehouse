###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Filters
  # Resolves a project group, and limits the enrollments `apply_criteria` returns, against
  # every project, including confidential ones, without checking what the user can see.
  # Cohort automation uses it so a cohort covers every project in its group.
  #
  # Build it only through `for_project_group`, so no submitted options reach it.
  class SystemProjectFilter < FilterBase
    private_class_method :new

    def self.for_project_group(project_group)
      new(
        user_id: User.setup_system_user.id,
        project_group_ids: [project_group.id],
      )
    end

    def all_project_scope
      GrdaWarehouse::Hud::Project.all
    end

    def criteria_project_scope
      GrdaWarehouse::Hud::Project.all
    end

    # A new project group isn't visible to the system user until system group maintenance runs
    private def viewable_project_group_scope
      GrdaWarehouse::ProjectGroup.all
    end
  end
end
