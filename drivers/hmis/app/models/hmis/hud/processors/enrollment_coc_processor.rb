###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis::Hud::Processors
  class EnrollmentCocProcessor < Base
    def factory_name
      :enrollment_coc_factory
    end

    def hud_type(_)
      nil # No schema, so hud_type is always nil
    end
  end
end
