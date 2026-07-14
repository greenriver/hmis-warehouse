###
# Copyright Green River Data Group, Inc.
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
    argument :owner_type, Types::HmisSchema::Enums::CeMatchRuleOwnerType, required: false
    argument :rule_type, Types::HmisSchema::Enums::CeMatchRuleType, required: false
    argument :priority_rank, Integer, required: false
    argument :expression, String, required: false
    argument :structured_expression, Types::HmisSchema::CeMatchRuleStructuredExpressionInput, required: false
    argument :project_types, [Types::HmisSchema::Enums::ProjectType], required: false
    argument :funders, [Types::HmisSchema::Enums::Hud::FundingSource], required: false

    def to_rule_attributes
      input = to_h
      attrs = input.except(:structured_expression, :project_types, :funders).compact
      expr = expression_from_input
      attrs[:expression] = expr if expr
      attrs[:applicability_config] = applicability_config_from_input(input) if applicability_input?(input)
      attrs
    end

    private

    def applicability_input?(input)
      input.key?(:project_types) || input.key?(:funders)
    end

    def applicability_config_from_input(input)
      # The current UI submits projectTypes and funders together when updating
      # applicability, and the API expects future callers to do the same. If
      # either field is supplied, these inputs replace the complete applicability
      # config, so omitted or empty dimensions are cleared.
      config = {}
      config[:project_types] = input[:project_types] if input[:project_types].present?
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
