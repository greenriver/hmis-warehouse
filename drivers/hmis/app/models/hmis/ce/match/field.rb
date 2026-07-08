# frozen_string_literal: true

module Hmis::Ce::Match
  # Builder-facing CE match field metadata. Used by the GraphQL field queries and the expression translator.
  Field = Data.define(
    :id,
    :label,
    :multiple,
    :field_key,
    :source,
    :form_definition_identifier,

    # Intentionally uses form-builder vocabulary for item type and picklist fields,
    # even though this is situated in the CE module.
    # This is a tradeoff to make consistent info available to both:
    # - the presentation layer (GraphQL), which uses these to render choices for the field in the expression builder,
    # - the translation layer (ExpressionTranslator), which uses pick-list references to resolve enum-backed frontend values.
    :item_type,
    :pick_list_reference,
    :pick_list_options,
  )
end
