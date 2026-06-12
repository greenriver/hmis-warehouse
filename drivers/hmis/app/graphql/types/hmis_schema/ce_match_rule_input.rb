###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CeMatchRuleInput < BaseInputObject
    # Fields are not required on the input because this input type is shared by the create and update mutations.
    # Create still gets required-field enforcement from Rule's model/database validations.
    argument :name, String, required: false
    argument :owner_id, ID, required: false
    argument :owner_type, Types::HmisSchema::Enums::CeMatchRuleOwner, required: false
    argument :rule_type, Types::HmisSchema::Enums::CeMatchRuleType, required: false
    argument :priority_rank, Integer, required: false
    argument :expression, String, required: false
    argument :structured_expression, Types::HmisSchema::CeMatchRuleStructuredExpressionInput, required: false

    def to_rule_attributes
      attrs = to_h.except(:structured_expression).compact
      expr = expression_from_input
      attrs[:expression] = expr if expr
      attrs
    end

    private

    def expression_from_input
      return expression if expression.present?
      return unless structured_expression.present?

      Hmis::Ce::Match::Expression::ExpressionTranslator.from_structured(structured_expression.to_structured_expression)
    end
  end
end
