# frozen_string_literal: true

module Hmis::Ce::Match::Expression
  # ValueType is a category for CE Match Rule fields, aligned with Dentaku literal and
  # comparison semantics. Dentaku does not expose named type constants; literal classes are
  # Dentaku::AST::Numeric, Dentaku::AST::String, and Dentaku::AST::Logical (see ExpressionTranslator).
  ValueType = Data.define(:base_type, :multiple) # todo @Martha - is it worth it to put `multiple` in here? can it just be separate?
  ValueType::NUMERIC = ValueType.new(base_type: :numeric, multiple: false)
  ValueType::STRING = ValueType.new(base_type: :string, multiple: false)
  ValueType::LOGICAL = ValueType.new(base_type: :logical, multiple: false)
  ValueType::DATETIME = ValueType.new(base_type: :datetime, multiple: false)
  ValueType::NUMERIC_ARRAY = ValueType.new(base_type: :numeric, multiple: true)
  ValueType::STRING_ARRAY = ValueType.new(base_type: :string, multiple: true)

  ClientField = Data.define(
    :key,
    :value_type,
    :label,
    :description,
    :pick_list,
    :query,
    :arel_field,
    :joins,
    :format_for_display,
  )
end
