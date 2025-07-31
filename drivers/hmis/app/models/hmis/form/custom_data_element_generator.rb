###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# CustomDataElementGenerator is responsible for generating and validating
# CustomDataElementDefinitions (CDEDs) for a given form definition.
#
# This class provides functionality to:
# - Generate new CDEDs for form items that lack a mapping.
# - Validate existing CDED mappings.
#
# Usage:
# generator = Hmis::Form::CustomDataElementGenerator.new(
#   definition: form_definition,
#   hud_user: current_hud_user,
#   create_missing_mappings: true, # Whether to modify the form definition JSON to include new CDED mappings
#   set_form_definition_identifier: true, # Whether to set the form_definition_identifier on newly created CDEDs
#   data_source: optional_data_source # Optional data source for the CDEDs
# )
# cdeds = generator.run
# cdeds.each(&:save!) # Save the generated CDEDs
# definition.save! # Save the updated form definition with new CDED mappings, if create_missing_mappings was passed
#
# This class ensures that all generated CDEDs are unique and conform to the
# expected structure and type for the given form definition.
module Hmis
  module Form
    class CustomDataElementGenerator
      def initialize(definition:, create_missing_mappings:, set_form_definition_identifier: true, data_source: nil, hud_user: nil)
        @definition = definition
        @cdeds = []
        @data_source = data_source || ::GrdaWarehouse::DataSource.hmis.first # ok? raise if in prod?
        @hud_user = hud_user || Hmis::Hud::User.system_user(data_source_id: @data_source.id)
        @create_missing_mappings = create_missing_mappings
        @set_form_definition_identifier = set_form_definition_identifier
      end

      def run
        # Prefix all CDED keys with a slug of the form identifier
        cded_key_prefix = @definition.identifier.parameterize.underscore

        cded_attributes = {
          form_definition_identifier: @set_form_definition_identifier ? @definition.identifier : nil,
          data_source: @data_source,
          user_id: @hud_user.user_id,
        }

        # Walk Definition to initialize CustomDataElementDefinitions for any questions that don't already have a mapping
        # and modify the definition JSON to reference the new CDED key
        @definition.walk_definition_nodes do |item_hash|
          item = Oj.load(item_hash.to_json, mode: :compat, object_class: OpenStruct)
          next if skip_item?(item)

          # Lookup existing CDED referenced by item.mapping.custom_field_key
          existing_cded = lookup_mapped_cded(item)

          # If the item references an existing CDED, validate that it has the expected type.
          # Update the label if it has changed.
          if existing_cded
            Hmis::Form::DefinitionValidator.validate_cded(item: item, cded: existing_cded)
            existing_cded.label = generate_cded_field_label(item)
            @cdeds << existing_cded if existing_cded.changed?
            next
          end

          custom_field_key = item.mapping&.custom_field_key

          # Proceed unless item specifies a custom_field_key mapping, OR create_missing_mappings is true.
          # @create_missing_mappings will mutate the definition to add new mappings.
          next unless custom_field_key || @create_missing_mappings

          # Determine the owner type for the CDED
          owner_type = determine_owner_type(item)
          # Use referenced key for CDED if present, otherwise generate a new unique key based on link_id
          cded_key = custom_field_key || ensure_unique_key("#{cded_key_prefix}_#{item.link_id}", owner_type: owner_type)

          @cdeds << Hmis::Hud::CustomDataElementDefinition.new(
            key: cded_key,
            label: generate_cded_field_label(item),
            repeats: item.repeats || false,
            field_type: infer_cded_field_type(item),
            owner_type: owner_type,
            **cded_attributes,
          )

          # Modify the definition JSON to reference the new CDED key
          item_hash['mapping'] = { 'custom_field_key' => cded_key }
        end

        @cdeds
      end

      private

      # Generate appropriate 'label' for CDED based on item properties.
      def generate_cded_field_label(item)
        # Select the first non-blank label from the item properties. Prefers labels that are typically shorter.
        label = [
          item.readonly_text,
          item.brief_text,
          item.text,
          item.link_id.humanize,
        ].compact_blank.first

        ActionView::Base.full_sanitizer.sanitize(label)[0..100].strip
      end

      # Infer CDED field_type based on Form Item type.
      def infer_cded_field_type(item)
        case item.type
        when 'STRING', 'TEXT', 'CHOICE', 'TIME_OF_DAY', 'OPEN_CHOICE'
          'string'
        when 'BOOLEAN'
          'boolean'
        when 'DATE'
          'date'
        when 'INTEGER'
          'integer'
        when 'CURRENCY'
          'float'
        when 'FILE', 'IMAGE'
          'file'
        else
          raise "unable to determine cded type for #{item.type}"
        end
      end

      def skip_item?(item)
        Hmis::Form::Definition::NON_QUESTION_ITEM_TYPES.include?(item.type) ||
          item.mapping&.field_name
      end

      def lookup_mapped_cded(item)
        custom_field_key = item.mapping&.custom_field_key
        return unless custom_field_key

        owner_type = determine_owner_type(item)
        found = Hmis::Hud::CustomDataElementDefinition.find_by(owner_type: owner_type, key: custom_field_key, data_source: @data_source)
        raise "Form '#{@definition.identifier}' item '#{item.link_id}' references a CDED '#{custom_field_key}' belongs to a different form ('#{found.form_definition_identifier}')" if found&.form_definition_identifier && found&.form_definition_identifier != @definition.identifier

        found
      end

      def determine_owner_type(item)
        owner_type = if item.mapping&.record_type
          Hmis::Form::RecordType.find(item.mapping.record_type).owner_type
        else
          @definition.owner_class.sti_name # inferred from form 'role'
        end

        # SPECIAL CASE: owner should never be the HmisService model (which is backed by a view).
        # Usually owner should be Hmis::Hud::CustomService, unless this is the stock HUD service form,
        # in which case the cded should be collected onto the Hmis::Hud::Service.
        if owner_type == 'Hmis::Hud::HmisService'
          return @definition.identifier == 'service' ? 'Hmis::Hud::Service' : 'Hmis::Hud::CustomService'
        end

        owner_type
      end

      # Ensure the CDED key is unique for the given owner type
      # If a CDED with the same key already exists, append a number to the key
      # to make it unique, up to a maximum of 50 attempts.
      def ensure_unique_key(key, owner_type:)
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
