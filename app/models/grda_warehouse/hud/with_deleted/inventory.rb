# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# NOTE: This provides an unscoped duplicate of Enrollment for use with exports
# that should ignore acts as paranoid completely
module GrdaWarehouse::Hud::WithDeleted
  class Inventory < GrdaWarehouse::Hud::Inventory
    default_scope { unscope where: paranoia_column }

    belongs_to :project_with_deleted, class_name: 'GrdaWarehouse::Hud::WithDeleted::Project', query_constraints: [:ProjectID, :data_source_id], primary_key: [:ProjectID, :data_source_id], optional: true
    alias_method :project, :project_with_deleted
  end
end
