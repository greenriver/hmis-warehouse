###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module ManagesCeMatchRules
  extend ActiveSupport::Concern

  IMPACT_WARNING_RATIO = 0.25

  private

  def validate_input(input, expression_required:)
    # If expression is required (create), it's invalid unless exactly one of [expression, structured_expression] is present
    return if expression_required && input.expression.present? ^ input.structured_expression.present?
    # If expression is not required (update), they can't both be present. Either could be provided, or both could be blank.
    return if !expression_required && (input.expression.blank? || input.structured_expression.blank?)

    errors = HmisErrors::Errors.new
    errors.add(:expression, :invalid, message: 'Provide exactly one of expression or structuredExpression.')
    errors
  end

  def validate_expression(rule)
    Hmis::Ce::Match::Expression::Validator.call(rule.expression)
  end

  def save_rule(rule)
    rule.save!
    nil
  rescue ActiveRecord::RecordInvalid
    errors = HmisErrors::Errors.new
    errors.add_ar_errors(rule.errors.errors)
    errors
  end

  def impact_warnings(rule)
    result = Hmis::Ce::Match::RuleChangeImpactCalculator.for_rule(rule: rule)

    warn_unit_groups = result.affected_unit_groups.select do |unit_group_info|
      # Warn about this unit group if the rule change will cause many candidates to be removed
      unit_group_info.current_candidate_count.positive? &&
        unit_group_info.removed_candidate_count.to_f / unit_group_info.current_candidate_count >= IMPACT_WARNING_RATIO
    end

    return HmisErrors::Errors.new if warn_unit_groups.empty?

    errors = HmisErrors::Errors.new
    errors.add(
      :base,
      :information,
      full_message: 'This rule would remove a substantial number of current candidates.',
      severity: :warning,
      data: {
        affectedUnitGroups: warn_unit_groups.map { |unit_group_info| impact_warning_data(unit_group_info) },
      }, # todo @martha - determine how this will be displayed in the frontend, not sure about the `data` pattern
    )
    errors
  end

  def impact_warning_data(unit_group_info)
    unit_group = unit_group_info.unit_group
    {
      unitGroupId: unit_group.id.to_s,
      unitGroupName: unit_group.name,
      currentCandidateCount: unit_group_info.current_candidate_count,
      removedCandidateCount: unit_group_info.removed_candidate_count,
    }
  end
end
