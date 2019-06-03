###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

# NOTE: This provides an unscoped duplicate of Project for use with exports
# that should ignore acts as paranoid completely
module GrdaWarehouse::Hud::WithDeleted
  class Organization < GrdaWarehouse::Hud::Organization
    default_scope {unscope where: paranoia_column}
  end
end