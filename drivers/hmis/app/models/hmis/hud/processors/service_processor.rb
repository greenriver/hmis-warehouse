# frozen_string_literal: true

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

    # This post-processing step provides functionality needed for the FY2024 service form. It can be removed after FY2026 changes
    # have been deployed.
    #
    # FY2024 service form collects FA Start Date for SSVF Financial Assistance, and does NOT collect Date Provided. (Needs processor to store FA Start Date in Date Provided field)
    # FY2026 service form collects both Date Provided and FA Start Date independently for SSVF Financial Assistance
    def post_process
      service = @processor.send(factory_name)

      # Overwrite the DateProvided field if FA Start Date was submitted and Date Provided was not
      date_provided_submitted = @hud_values.key?('dateProvided') && @hud_values['dateProvided'] != HIDDEN_FIELD_VALUE
      service.date_provided = service.fa_start_date if service.fa_start_date.present? && !date_provided_submitted
    end
  end
end
