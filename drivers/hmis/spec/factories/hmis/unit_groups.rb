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

    # Caution: When using this factory to create a unit with a candidate_pool,
    # if the unit does not have rules, then the after_create callback will overwrite the candidate_pool back to nil.
    # Work around this by stubbing the CandidatePoolBuilder in tests that don't need to test its functionality:
    # allow_any_instance_of(Hmis::Ce::Match::CandidatePoolBuilder).to receive(:call)
  end
end
