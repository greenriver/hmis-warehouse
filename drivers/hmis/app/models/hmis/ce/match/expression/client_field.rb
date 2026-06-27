# frozen_string_literal: true

module Hmis::Ce::Match::Expression
  # Value categories for CE Match Rule client fields, aligned with Dentaku literal and
  # comparison semantics. Dentaku does not expose named type constants; literal classes are
  # Dentaku::AST::Numeric, Dentaku::AST::String, and Dentaku::AST::Logical (see ExpressionTranslator).
  module ValueType
    NUMERIC = :numeric
    STRING = :string
    LOGICAL = :logical
    DATETIME = :datetime
  end

  ClientField = Data.define(
    :key,
    :value_type,
    :multiple,
    :description,
  )
end
