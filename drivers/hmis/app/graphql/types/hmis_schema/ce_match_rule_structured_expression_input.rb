###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CeMatchRuleStructuredExpressionInput < BaseInputObject
    argument :operator, Types::HmisSchema::Enums::CeMatchRuleBooleanOperator, required: true
    argument :clauses, [Types::HmisSchema::CeMatchRuleClauseInput], required: true

    def to_structured_expression
      Hmis::Ce::Match::Expression::StructuredExpression.new(
        operator: operator,
        clauses: clauses.map(&:to_structured_clause),
      )
    end
  end
end
