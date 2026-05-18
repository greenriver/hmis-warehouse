# frozen_string_literal: true

module Hmis::Ce::Match::Expression
  # Read-only structured view of a flat AND-only or OR-only CE match expression.
  # For now, if the expression is more complex, we skip translation and fallback to the free text expression.
  class StructuredExpression
    Clause = Struct.new(:field, :comparator, :value, keyword_init: true)

    attr_reader :operator, :clauses

    def initialize(operator:, clauses:)
      @operator = operator.to_sym
      @clauses = clauses
    end

    def ==(other)
      other.is_a?(StructuredExpression) &&
        operator == other.operator &&
        clauses == other.clauses
    end
    alias_method :eql?, :==
  end
end
