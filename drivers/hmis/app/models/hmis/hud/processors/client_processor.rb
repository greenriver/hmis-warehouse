###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis::Hud::Processors
  class ClientProcessor < Base
    def process(field, value)
      attribute_name = hud_name(field)
      attribute_value = attribute_value_for_enum(hud_type(field), value)

      # Skip SSN/DOB fields if hidden, because they are always hidden due to lack of permissions (see client.json form definition)
      return if value == Base::HIDDEN_FIELD_VALUE && ['ssn', 'dob'].include?(attribute_name)

      attributes = case attribute_name
      when 'race'
        race_attributes(Array.wrap(attribute_value))
      when 'gender'
        gender_attributes(Array.wrap(attribute_value))
      when 'pronouns'
        { attribute_name => Array.wrap(attribute_value).any? ? Array.wrap(attribute_value).join('|') : nil }
      when 'ssn'
        { attribute_name => attribute_value.present? ? attribute_value.gsub(/[^\dXx]/, '') : nil }
      when 'ssn_data_quality'
        # If hidden due to permissions, set to old value or 99
        attribute_value = @processor.send(factory_name).ssn_data_quality || 99 if value == Base::HIDDEN_FIELD_VALUE
        { attribute_name => attribute_value }
      when 'dob_data_quality'
        # If hidden due to permissions, set to old value or 99
        attribute_value = @processor.send(factory_name).dob_data_quality || 99 if value == Base::HIDDEN_FIELD_VALUE
        { attribute_name => attribute_value }
      else
        { attribute_name => attribute_value }
      end

      @processor.send(factory_name).assign_attributes(attributes)
    end

    def factory_name
      :owner_factory
    end

    def schema
      Types::HmisSchema::Client
    end

    def information_date(_)
    end

    # TODO: move actual logic here once ClientInputTransformer is removed because we stop using that mutation
    private def race_attributes(attribute_value)
      Types::HmisSchema::Transformers::ClientInputTransformer.multi_field_attrs(
        attribute_value,
        Hmis::Hud::Client.race_enum_map,
        :data_not_collected,
        :RaceNone,
      )
    end

    private def gender_attributes(attribute_value)
      Types::HmisSchema::Transformers::ClientInputTransformer.multi_field_attrs(
        attribute_value,
        Hmis::Hud::Client.gender_enum_map,
        'Data not collected',
        :GenderNone,
      )
    end
  end
end
