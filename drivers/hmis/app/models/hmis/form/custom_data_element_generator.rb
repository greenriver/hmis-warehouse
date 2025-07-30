# frozen_string_literal: true

module Hmis
  module Form
    class CustomDataElementGenerator
      def initialize(definition:, hud_user:, data_source: nil)
        @definition = definition
        @hud_user = hud_user
        @cdeds = []
        @data_source = data_source || GrdaWarehouse::DataSource.hmis.first
      end

      # mutates `definition.definition`
      # initializes `@cdeds` with CustomDataElementDefinitions to be saved
      # returns array of initialized CustomDataElementDefinitions to be saved
      def generate
        # Prefix all CDED keys with a slug of the form identifier
        cded_key_prefix = @definition.identifier.parameterize.underscore

        cded_attributes = {
          form_definition_identifier: @definition.identifier,
          data_source: @data_source,
          user_id: hud_user.user_id,
        }

        # Walk Definition to initialize CustomDataElementDefinitions for any questions that don't already have a mapping
        # and modify the definition JSON to reference the new CDED key
        @definition.walk_definition_nodes do |item_hash|
          item = Oj.load(item_hash.to_json, mode: :compat, object_class: OpenStruct)          
          next if skip_item?(item)

          if item.mapping&.custom_field_key
            # TODO: if item has item.mapping&.custom_field_key, validate that the CDED exists and has the expected type. Also update the CDED label. If the referenced CDED doesn't exist, create it.
          end

          owner_type = determine_owner_type(item)
          cded_key = ensure_unique_key(owner_type, "#{cded_key_prefix}_#{item.link_id}")

          @cdeds << Hmis::Hud::CustomDataElementDefinition.new(
            key: cded_key,
            label: Hmis::Form::Definition.generate_cded_field_label(item),
            repeats: item.repeats || false,
            field_type: Hmis::Form::Definition.infer_cded_field_type(item.type),
            owner_type: owner_type,
            **cded_attributes,
          )

          # Modify the definition JSON to reference the new CDED key
          item_hash['mapping'] = { 'custom_field_key' => cded_key }
        end

        @cdeds
      end

      private

      def skip_item?(item)
        Hmis::Form::Definition::NON_QUESTION_ITEM_TYPES.include?(item.type) ||
          item.mapping&.field_name
      end

      def determine_owner_type(item)
        owner_type = if item.mapping&.record_type
          Hmis::Form::RecordType.find(item.mapping.record_type).owner_type
        else
          @definition.owner_class.sti_name # inferred from form 'role'
        end

        # SPECIAL CASE: owner should never be the HmisService model which is a view. Assume custom service
        # unless this is the specific HUD service form, in which case it is a Hmis::Hud::Service
        if owner_type == 'Hmis::Hud::HmisService'
          return @definition.identifier == 'service' ? 'Hmis::Hud::Service' : 'Hmis::Hud::CustomService'
        end

        owner_type
      end

      # Ensure the CDED key is unique for the given owner type
      # If a CDED with the same key already exists, append a number to the key
      # to make it unique, up to a maximum of 50 attempts.
      def ensure_unique_key(owner_type, key)
        return key unless Hmis::Hud::CustomDataElementDefinition.exists?(owner_type: owner_type, key: key)

        count = 1
        possible_key = key
        while Hmis::Hud::CustomDataElementDefinition.exists?(owner_type: owner_type, key: possible_key)
          count += 1
          possible_key = "#{key}_#{count}"
          raise 'Unique key generation failed after 50 attempts' if count > 50
        end
        possible_key
      end
    end
  end
end
