###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module ManagesCeMatchRules
  extend ActiveSupport::Concern

  # If the rule change will remove more than 25% of the current candidates, warn the user
  IMPACT_WARNING_RATIO = 0.25

  private

  def validate_input(input, expression_required:)
    errors = HmisErrors::Errors.new
    # If expression is required (create), it's invalid unless exactly one of [expression, structured_expression] is present
    return errors if expression_required && input.expression.present? ^ input.structured_expression.present?
    # If expression is not required (update), they can't both be present. Either could be provided, or both could be blank.
    return errors if !expression_required && (input.expression.blank? || input.structured_expression.blank?)

    errors.add(:expression, :invalid, message: 'Provide exactly one of expression or structuredExpression.')
    errors
  end

  def validate_expression(rule)
    Hmis::Ce::Match::Expression::Validator.call(rule.expression)
  end

  def save_rule(rule)
    rule.save!
    HmisErrors::Errors.new
  rescue ActiveRecord::RecordInvalid
    errors = HmisErrors::Errors.new
    errors.add_ar_errors(rule.errors.errors)
    errors
  end

  def impact_warnings(rule)
    errors = HmisErrors::Errors.new
    result = Hmis::Ce::Match::RuleChangeImpactCalculator.for_rule(rule: rule)

    warn_unit_groups = result.affected_unit_groups.select do |unit_group_info|
      # Warn about this unit group if the rule change will cause many candidates to be removed
      unit_group_info.current_candidate_count.positive? &&
        # casting removed candidate count to float to avoid integer division rounding
        unit_group_info.removed_candidate_count.to_f / unit_group_info.current_candidate_count >= IMPACT_WARNING_RATIO
    end

    return errors if warn_unit_groups.empty?

    errors.add(
      :base,
      :information,
      full_message: 'This rule would remove a substantial number of currently eligible clients.',
      severity: :warning,
      data: {
        affectedUnitGroups: warn_unit_groups.map do |unit_group_info|
          unit_group = unit_group_info.unit_group
          {
            unitGroupId: unit_group.id.to_s,
            unitGroupName: unit_group.name,
            currentCandidateCount: unit_group_info.current_candidate_count,
            removedCandidateCount: unit_group_info.removed_candidate_count,
          }
        end,
      },
    )
    errors
  end
end
