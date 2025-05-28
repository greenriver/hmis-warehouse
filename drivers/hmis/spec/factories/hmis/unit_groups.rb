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
    association(:workflow_template, factory: :hmis_workflow_definition_template)
  end
end
