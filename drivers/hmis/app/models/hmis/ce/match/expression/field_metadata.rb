# frozen_string_literal: true

module Hmis::Ce::Match::Expression
  FieldMetadata = Data.define(
    :id,
    :key,
    :label,
    :item_type,
    :repeats,
    :expression_field,
    :form_definition_identifier,
    :pick_list_options,
    :pick_list_reference,
  )
end
