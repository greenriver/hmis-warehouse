###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis::Hud::Processors
  class YouthEducationStatusProcessor < Base
    def factory_name
      :youth_education_status_factory
    end

    def schema
      Types::HmisSchema::YouthEducationStatus
    end
  end
end
