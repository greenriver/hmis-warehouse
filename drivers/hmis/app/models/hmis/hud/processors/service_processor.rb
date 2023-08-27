###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
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
      when 'fa_start_date'
        # If FA Start Date is present, the Date Provided should match it
        if attribute_value.present?
          { attribute_name => attribute_value, 'date_provided' => attribute_value }
        else
          { attribute_name => attribute_value }
        end
      when 'sub_type_provided'
        # Enum value is set up like "144:4:6" (record type : type provided : sub type provided)
        { attribute_name => attribute_value.split(':').last }
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

    def assign_metadata
      hmis_service = @processor.owner_factory
      hmis_service.assign_attributes(user: @processor.hud_user)
      hmis_service.owner.assign_attributes(user: @processor.hud_user)
      return unless hmis_service.hud_service?

      hmis_service.owner.assign_attributes(
        record_type: hmis_service.service_type&.hud_record_type,
        type_provided: hmis_service.service_type&.hud_type_provided,
      )
    end
  end
end
