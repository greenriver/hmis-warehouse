###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis::Hud::Processors
  class ServiceProcessor < Base
    def process(field, value)
      attribute_name = ar_attribute_name(field)
      attribute_value = attribute_value_for_enum(graphql_enum(field), value)

      # service is a Hmis::Hud::Service or Hmis::Hud::CustomService
      service = @processor.service_factory

      attributes = case attribute_name
      when 'sub_type_provided'
        # Enum value is set up like "144:4:6" (record type : type provided : sub type provided)
        { attribute_name => attribute_value&.split(':')&.last }
      else
        { attribute_name => attribute_value }
      end

      service.assign_attributes(attributes)
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
