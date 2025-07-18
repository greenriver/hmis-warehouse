###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

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

  factory :hmis_project_ce_config, class: 'Hmis::ProjectCeConfig' do
    created_at { Time.current }
    updated_at { Time.current }
    enabled { true }

    transient do
      accepts_direct_referrals { false }
      supports_waitlist_referrals { true }
      accepts_direct_referrals_from { nil }
    end

    after(:build) do |config, evaluator|
      options = {}
      options['accepts_direct_referrals'] = evaluator.accepts_direct_referrals
      options['supports_waitlist_referrals'] = evaluator.supports_waitlist_referrals
      options['accepts_direct_referrals_from'] = evaluator.accepts_direct_referrals_from if evaluator.accepts_direct_referrals_from.present?
      config.config_options = options.to_json
    end
  end
end
