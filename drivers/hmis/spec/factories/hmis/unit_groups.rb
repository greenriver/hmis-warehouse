###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :hmis_unit_group, class: 'Hmis::UnitGroup' do
    sequence(:name) { |n| "Unit Group #{n}" }
    project { association :hmis_hud_project }
    workflow_template { association :hmis_workflow_definition_template, data_source: project.data_source }
    # TODO(#8157) - add unit_type
    # unit_type { association :hmis_unit_type }

    before(:create) do |unit_group|
      if unit_group.candidate_pool.present? && unit_group.ce_match_rules.empty? && !unit_group.deleted?
        # The UnitGroup model has an after_create callback that rebuilds candidate pools.
        # In tests, if a unit group factory is passed a candidate_pool, but no rules apply,
        # then the after_create callback will overwrite the candidate_pool back to nil.
        # This is inconvenient in tests that don't care about the CandidatePoolBuilder behavior
        # and just want to create a UnitGroup/CandidatePool that's considered active.
        # Work around this by creating dummy rules that match the provided candidate pool.

        create(:hmis_ce_match_rule, owner: unit_group, rule_type: 'eligibility_requirement', expression: unit_group.candidate_pool.requirement_expression)
        # Hack: Expect the priority expression to be a string like "{1}" and just remove the curly braces.
        # This won't work if the priority expression is more complex, like {1, 2, etc.}
        # In those cases, the caller probably does care about the behavior of CandidatePoolBuilder,
        # and should manually create rules for the unit group that match the candidate pool.
        create(:hmis_ce_match_rule, owner: unit_group, rule_type: 'priority_scheme', expression: unit_group.candidate_pool.priority_expression.tr('{}', ''), priority_rank: 1)
      end
    end
  end
end
