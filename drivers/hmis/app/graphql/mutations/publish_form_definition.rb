###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class PublishFormDefinition < CleanBaseMutation
    argument :id, ID, required: true

    field :form_identifier, Types::Forms::FormIdentifier, null: false

    def resolve(id:)
      definition = Hmis::Form::Definition.find_by(id: id)
      raise 'not found' unless definition

      access_denied! unless current_user.can_manage_forms_for_role?(definition.role)

      raise 'only draft forms can be published' unless definition.draft?

      previous_published_form = Hmis::Form::Definition.find_by(
        identifier: definition.identifier,
        status: Hmis::Form::Definition::PUBLISHED,
      )

      definition.status = Hmis::Form::Definition::PUBLISHED
      # Ensure HUD requirements are set correctly (if applicable). This could mutate the definition.
      definition.set_hud_requirements

      Hmis::Form::Definition.transaction do
        # Retire the previously published version
        previous_published_form&.update!(status: Hmis::Form::Definition::RETIRED)

        # Add any missing custom field keys to the form definition (for new questions)
        new_cdeds = add_missing_custom_field_keys(definition)
        # Save any new CustomDataElementDefinitions
        new_cdeds.each(&:save!)

        # Validate form structure, including HUD requirements
        validation_errors = definition.validate_json_form
        return { errors: validation_errors } if validation_errors.any?

        # Save the updated form definition
        definition.save!
      end

      {
        form_identifier: definition,
      }
    end

    # Adds missing `{mapping: {custom_field_key: '...'}}` to all questions in the form definition
    # Mutates definition.items, adds `mapping.custom_field_key`
    # Returns array of initialized CustomDataElementDefinitions to be saved (for new questions only)
    def add_missing_custom_field_keys(definition)
      # CustomDataElementDefinitions to be saved
      cdeds = []

      # Prefix all CDED keys with a slug of the form identifier
      cded_key_prefix = definition.identifier.parameterize.underscore

      # Common attributes for any CDEDs we will initialize
      data_source = GrdaWarehouse::DataSource.hmis.first
      # FIXME: some definitions support multiple owner_types (SERVICE, NEW_CLIENT_ENROLLMENT).
      # This needs to be updated to account for that. The mapping.record_type field should specify the record type.
      owner_type = definition.owner_class.sti_name

      cded_attributes = {
        owner_type: owner_type,
        form_definition_identifier: definition.identifier,
        data_source: data_source,
        user_id: Hmis::Hud::User.from_user(current_user).user_id,
      }

      # Walk Definition to initialize CustomDataElementDefinitions for any questions that don't already have a mapping
      definition.walk_definition_nodes do |item_hash|
        item = Oj.load(item_hash.to_json, mode: :compat, object_class: OpenStruct)

        # Skip non-questions items (Groups and Display items)
        next if Hmis::Form::Definition::NON_QUESTION_ITEM_TYPES.include?(item.type)
        # Skip items that already map to a standard (HUD) field
        next if item.mapping&.field_name
        # Skip items that already map to a custom data element
        next if item.mapping&.custom_field_key

        cded_key = "#{cded_key_prefix}_#{item.link_id}"
        cded_key = ensure_unique_key(owner_type, cded_key)

        cdeds << Hmis::Hud::CustomDataElementDefinition.new(
          key: cded_key,
          label: Hmis::Form::Definition.generate_cded_field_label(item),
          repeats: item.repeats || false,
          field_type: Hmis::Form::Definition.infer_cded_field_type(item.type),
          **cded_attributes,
        )

        # Modify the definition JSON to reference the new CDED key
        item_hash['mapping'] = { 'custom_field_key' => cded_key }
      end

      cdeds
    end

    def ensure_unique_key(owner_type, key)
      return key unless Hmis::Hud::CustomDataElementDefinition.exists?(owner_type: owner_type, key: key)

      count = 1
      possible_key = key
      while Hmis::Hud::CustomDataElementDefinition.exists?(owner_type: owner_type, key: possible_key)
        count += 1
        possible_key = "#{key}_#{count}"
        raise if count > 50 # Prevent infinite loop
      end
      possible_key
    end
  end
end
