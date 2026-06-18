###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# NOTE: This provides an unscoped duplicate of ProjectCoc for use with exports
# that should ignore acts as paranoid completely
module GrdaWarehouse::Hud::WithDeleted
  class ProjectCoc < GrdaWarehouse::Hud::ProjectCoc
    default_scope { unscope where: paranoia_column }
  end
end
