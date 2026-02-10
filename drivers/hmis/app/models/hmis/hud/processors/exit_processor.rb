###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Hmis::Hud::Processors
  class ExitProcessor < Base
    def process(field, value)
      attribute_name = ar_attribute_name(field)
      enum = graphql_enum(field)

      attributes = case attribute_name
      when 'aftercare_methods'
        attributes_from_multi_select(value, enum: enum, attribute_map: HudHelper.util.aftercare_method_fields)
      when 'counseling_methods'
        attributes_from_multi_select(value, enum: enum, attribute_map: HudHelper.util.counseling_method_fields)
      else
        { attribute_name => attribute_value_for_enum(enum, value) }
      end
      @processor.send(factory_name).assign_attributes(attributes)
    end

    def factory_name
      :exit_factory
    end

    def relation_name
      :exit
    end

    def schema
      Types::HmisSchema::Exit
    end

    def information_date(_)
      # Exits don't have an information date to be set
    end
  end
end
