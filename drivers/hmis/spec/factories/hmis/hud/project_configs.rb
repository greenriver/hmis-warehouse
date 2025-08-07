# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

FactoryBot.define do
  factory :hmis_project_auto_enter_config, class: 'Hmis::ProjectAutoEnterConfig' do
    created_at { Time.current }
    updated_at { Time.current }
  end

  factory :hmis_project_auto_exit_config, class: 'Hmis::ProjectAutoExitConfig' do
    created_at { Time.current }
    updated_at { Time.current }
    config_options { { 'length_of_absence_days': 30 }.to_json }
  end

  factory :hmis_project_staff_assignment_config, class: 'Hmis::ProjectStaffAssignmentConfig' do
    association :project, factory: :hmis_hud_project
    created_at { Time.current }
    updated_at { Time.current }
  end
end
