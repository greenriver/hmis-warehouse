###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CustomDataElement < Types::BaseObject
    field :id, ID, null: false
    field :key, String, null: false
    field :field_type, HmisSchema::Enums::CustomDataElementType, null: false
    field :label, String, null: false
    field :repeats, Boolean, null: false
    field :display_hooks, [HmisSchema::Enums::DisplayHook], null: false, description: 'Where to display the custom field in the application'
    field :value, HmisSchema::CustomDataElementValue, null: true
    field :values, [HmisSchema::CustomDataElementValue], null: true
    field :display_value, String, null: true, description: 'Human-readable value, with pick-list codes resolved to labels'

    # object is a Hmis::Hud::GraphqlCdeValueAdapter

    def activity_log_object_identity
      object.id
    end

    def display_value
      # doesn't cause n+1, since object is a GraphqlCdeValueAdapter Struct that already has the cded loaded in memory
      cded = object.definition
      identifier = cded.form_definition_identifier
      return nil if identifier.blank?

      labels_by_key = dataloader.
        with(Sources::CdePickListMetadataByIdentifier, cded.data_source_id, current_user).
        load(identifier)
      labels = labels_by_key[cded.key]
      return nil if labels.blank?

      values = object.repeats ? (object.values || []) : [object.value].compact
      codes = values.map(&:value_string).compact
      return nil if codes.empty?

      codes.map { |code| labels[code] || code }.join(', ')
    end
  end
end
