###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Mutations
  module Ce
    class CreateCeMatchRule < Mutations::CleanBaseMutation
      include ManagesCeMatchRules

      argument :input, Types::HmisSchema::CeMatchRuleInput, required: true
      argument :confirmed, Boolean, required: false

      field :rule, Types::HmisSchema::CeMatchRule, null: true

      def resolve(input:, confirmed: false)
        # Check globally that the user has permission to create rules
        access_denied! unless policy_for(Hmis::Ce::Match::Rule, policy_type: :ce_match_rule).can_create?

        errors = validate_input(input, expression_required: true)
        return { rule: nil, errors: errors } if errors&.any?

        # Check the rule instance policy, to confirm the user can create a rule for this owner (it's in the right DS)
        rule = Hmis::Ce::Match::Rule.new(input.to_rule_attributes)
        access_denied! if rule.owner && !policy_for(rule, policy_type: :ce_match_rule).can_create?

        errors = validate_expression(rule)
        return { rule: nil, errors: errors } if errors.any?

        if rule.eligibility_requirement? && !confirmed
          warnings = impact_warnings(rule)
          return { rule: nil, errors: warnings } if warnings.any?
        end

        errors = save_rule(rule)
        return { rule: nil, errors: errors } if errors&.any?

        { rule: rule }
      end
    end
  end
end
