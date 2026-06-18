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
    # Underlying object is a Hmis::Ce::Match::Field

    field :id, ID, null: false
    field :key, String, null: false, description: 'The CDED key for this field, or the client field key for a client field'
    field :label, String, null: false, description: 'Human-readable label for this field'
    field :item_type, Types::Forms::Enums::ItemType, null: false, description: 'The type of the field, used for determining the possible values it can match against.'
    field :multiple, Boolean, null: false, description: 'Whether a client can have more than one value for the field.' # e.g. `age` is not multiple, but `open_enrollment_project_types` is.
    field :expression_field, String, null: false, description: 'The full-length identifier used in CE Match Rule expressions, such as "client.current_age" or "custom_assessment.my_assessment.my_score".'
    field :pick_list_reference, String, null: true, description: "The field's reference pick list, if applicable, such as `NoYesReasonsForMissingData`."
    field :pick_list_options, [Types::Forms::PickListOption], null: true, description: "The field's pick list options, if applicable."

    def key
      object.field_key.split('.').last
    end

    def expression_field
      object.field_key
    end
  end
end
