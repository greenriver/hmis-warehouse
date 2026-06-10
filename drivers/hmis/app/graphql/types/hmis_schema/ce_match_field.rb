###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CeMatchField < Types::BaseObject
    skip_activity_log
    description 'Field metadata for CE Match Rule expressions'

    # Underlying object is a Hmis::Ce::Match::Expression::FieldMetadata data type,
    # which can be backed by either:
    # - a CustomDataElementDefinition
    # - a derived client field from ClientFieldMap
    # See Hmis::Ce::Match::Expression::FieldMetadataResolver.
    field :id, ID, null: false
    field :key, String, null: false, description: 'The CDED key for this field, or the client field key for a client field'
    field :label, String, null: false
    field :item_type, Types::Forms::Enums::ItemType, null: false
    field :repeats, Boolean, null: false
    field :expression_field, String, null: false, description: 'The identifier used in CE Match Rule expressions'
    field :form_definition_identifier, String, null: true
    field :pick_list_reference, String, null: true
    field :pick_list_options, [Types::Forms::PickListOption], null: true
  end
end
