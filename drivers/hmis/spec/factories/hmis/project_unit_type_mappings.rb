###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :project_unit_type_mapping, class: 'Hmis::ProjectUnitTypeMapping' do
    project { association :hmis_hud_project }
    unit_type { association :hmis_unit_type }
    active { true }
  end
end
