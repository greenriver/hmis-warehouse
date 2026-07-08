###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Hmis::Ce::Match::Expression
  # Read-only structured view of a flat AND-only or OR-only CE match expression.
  # For now, if the expression is more complex, we skip translation and fallback to the free text expression.
  class StructuredExpression
    Clause = Data.define(:field, :comparator, :value, :field_source, :form_definition_identifier)

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
