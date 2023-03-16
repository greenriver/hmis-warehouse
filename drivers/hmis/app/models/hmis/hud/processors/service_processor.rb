###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis::Hud::Processors
  class ServiceProcessor < Base
    # Process as HUD Service. This needs to be updated to support Custom Services.
    def process(field, value)
      attribute_name = hud_name(field)
      attribute_value = attribute_value_for_enum(hud_type(field), value)

      return if attribute_name == 'custom_service_type'

      if attribute_name == 'type_provided'
        record_type, type_provided = attribute_value.split(':')
        @processor.send(factory_name).assign_attributes(
          record_type: record_type,
          type_provided: type_provided,
        )
        custom_service_type = Hmis::Hud::CustomServiceType.find_by(hud_record_type: record_type, hud_type_provided: type_provided)
        @processor.owner_factory.assign_attributes(custom_service_type: custom_service_type)
      else
        @processor.send(factory_name).assign_attributes(attribute_name => attribute_value)
      end
    end

    def factory_name
      :service_factory
    end

    def schema
      Types::HmisSchema::Service
    end

    def information_date(_)
    end
  end
end
