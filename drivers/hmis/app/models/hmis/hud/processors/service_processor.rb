###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis::Hud::Processors
  class ServiceProcessor < Base
    # Process as HUD Service. This needs to be updated to support Custom Services.
    def process(field, value)
      attribute_name = ar_attribute_name(field)
      attribute_value = attribute_value_for_enum(graphql_enum(field), value)

      return if attribute_name == 'custom_service_type'

      if attribute_name == 'type_provided' && attribute_value.present?
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

    def assign_metadata
      # FIXME: handle better - working on service processing on another branch
      @processor.owner_factory.assign_attributes(
        user: @processor.hud_user,
        data_source_id: @processor.hud_user.data_source_id,
      )
      @processor.service_factory.assign_attributes(
        user: @processor.hud_user,
        data_source_id: @processor.hud_user.data_source_id,
      )
    end
  end
end
