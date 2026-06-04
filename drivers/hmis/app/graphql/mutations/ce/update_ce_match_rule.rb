###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Mutations
  module Ce
    class UpdateCeMatchRule < Mutations::CleanBaseMutation
      include ManagesCeMatchRules

      argument :id, ID, required: true
      argument :input, Types::HmisSchema::CeMatchRuleInput, required: true
      argument :confirmed, Boolean, 'Whether warnings have been confirmed', required: false

      field :rule, Types::HmisSchema::CeMatchRule, null: true

      def resolve(id:, input:, confirmed: false)
        rule = Hmis::Ce::Match::Rule.find(id)
        access_denied! unless policy_for(rule, policy_type: :ce_match_rule).can_update?

        errors = validate_input(input, expression_required: false)
        return { rule: nil, errors: errors } if errors.any?

        rule.assign_attributes(input.to_rule_attributes)

        errors = validate_expression(rule)
        return { rule: nil, errors: errors } if errors.any?

        if preview_impact?(rule, confirmed)
          warnings = impact_warnings(rule)
          return { rule: nil, errors: warnings } if warnings.any?
        end

        errors = save_rule(rule)
        return { rule: nil, errors: errors } if errors.any?

        { rule: rule }
      end

      private

      def preview_impact?(rule, confirmed)
        # Preview the impact of this rule change if it's an eligibility requirement
        # (priority scheme changes don't remove candidates from the pool)
        rule.eligibility_requirement? &&
          !confirmed && # Only if the user didn't already confirm the change
          # Only if the expression or applicability config has changed.
          # - expression change can cause candidates to become ineligible
          # - applicability config change can cause this rule to apply to more pools, which may remove candidates from those pools
          (rule.will_save_change_to_expression? || rule.will_save_change_to_applicability_config?)
      end
    end
  end
end
