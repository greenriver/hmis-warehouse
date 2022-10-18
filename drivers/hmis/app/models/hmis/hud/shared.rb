###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
module Hmis::Hud::Shared
  extend ActiveSupport::Concern
  include Hmis::Hud::HasEnums
  include ::HmisStructure::Shared
end
