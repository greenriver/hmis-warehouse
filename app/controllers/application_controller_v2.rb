###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# this subclass supports the migration away from deprecated authorization methods. See
# conditional include in ApplicationController
class ApplicationControllerV2 < ApplicationController
  include ControllerAuthorizationV2
end
