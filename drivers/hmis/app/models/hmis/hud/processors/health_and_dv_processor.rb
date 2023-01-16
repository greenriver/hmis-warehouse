###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis::Hud::Processors
  class HealthAndDvProcessor < Base
    def process(field, value)
      attribute_name = hud_name(field)
      attribute_value = hud_type(field)&.value_for(value) || value
      @processor.health_and_dv_factory.assign_attributes(attribute_name => attribute_value)
    end

    def schema
      Types::HmisSchema::HealthAndDv
    end
  end
end
