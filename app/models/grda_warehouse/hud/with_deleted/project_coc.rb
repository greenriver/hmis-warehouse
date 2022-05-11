###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# NOTE: This provides an unscoped duplicate of ProjectCoc for use with exports
# that should ignore acts as paranoid completely
module GrdaWarehouse::Hud::WithDeleted
  class ProjectCoc < GrdaWarehouse::Hud::Project
    default_scope { unscope where: paranoia_column }
  end
end
