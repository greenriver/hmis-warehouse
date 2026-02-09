###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Hmis::Hud::Processors
  class CeParticipationProcessor < Base
    def process(field, value)
      attribute_name = ar_attribute_name(field)
      enum = graphql_enum(field)

      attributes = case attribute_name
      when 'ce_participation_services'
        attributes_from_multi_select(value, enum: enum, attribute_map: HudHelper.util.ce_participation_services_fields)
      else
        { attribute_name => attribute_value_for_enum(enum, value) }
      end
      @processor.send(factory_name).assign_attributes(attributes)
    end

    def factory_name
      # Assumes that this record is only edited via its own form.
      # To support creating/editing from the Project form, we'd need to add a separate ce_participation_factory
      :owner_factory
    end

    def relation_name
      :ce_participation
    end

    def schema
      Types::HmisSchema::CeParticipation
    end

    def information_date(_)
    end
  end
end
