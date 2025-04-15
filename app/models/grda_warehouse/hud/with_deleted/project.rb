# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# NOTE: This provides an unscoped duplicate of Project for use with exports
# that should ignore acts as paranoid completely
module GrdaWarehouse::Hud::WithDeleted
  class Project < GrdaWarehouse::Hud::Project
    default_scope { unscope where: paranoia_column }

    has_many_with_composite_keys :project_cocs_with_deleted, class_name: 'GrdaWarehouse::Hud::WithDeleted::ProjectCoc', keys: [:ProjectID]
    alias_method :project_cocs, :project_cocs_with_deleted
  end
end
