###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CeMatchRuleInput < BaseInputObject
    # Most fields are optional because this input is shared by create and update.
    # Applicability is always submitted as a complete value; empty arrays clear
    # the corresponding constraints.
    argument :name, String, required: false
    argument :owner_id, ID, required: false
    argument :owner_type, Types::HmisSchema::Enums::CeMatchRuleOwnerType, required: false
    argument :rule_type, Types::HmisSchema::Enums::CeMatchRuleType, required: false
    argument :priority_rank, Integer, required: false
    argument :expression, String, required: false
    argument :structured_expression, Types::HmisSchema::CeMatchRuleStructuredExpressionInput, required: false
    # Applicability limits the rule to projects with the selected HUD project types or funders.
    argument :project_types, [Types::HmisSchema::Enums::ProjectType], required: true
    argument :funders, [Types::HmisSchema::Enums::Hud::FundingSource], required: true

    def to_rule_attributes
      input = to_h
      attrs = input.except(:structured_expression, :project_types, :funders).compact
      expr = expression_from_input
      attrs[:expression] = expr if expr
      attrs[:applicability_config] = applicability_config_from_input(input)
      attrs
    end

    private

    def applicability_config_from_input(input)
      config = {}
      config[:project_types] = input[:project_types] if input[:project_types].present?
      # Input uses :funders; model stores :project_funders to match HUD terminology
      config[:project_funders] = input[:funders] if input[:funders].present?
      config
    end

    def expression_from_input
      return expression if expression.present?
      return unless structured_expression.present?

      Hmis::Ce::Match::Expression::ExpressionTranslator.from_structured(structured_expression.to_structured_expression)
    end
  end
end
