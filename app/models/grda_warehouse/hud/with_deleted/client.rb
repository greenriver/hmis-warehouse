###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

# NOTE: This provides an unscoped duplicate of Client for use with exports
# that should ignore acts as paranoid completely
module GrdaWarehouse::Hud::WithDeleted
  class Client < GrdaWarehouse::Hud::Client
    default_scope {unscope where: paranoia_column}
  end
end