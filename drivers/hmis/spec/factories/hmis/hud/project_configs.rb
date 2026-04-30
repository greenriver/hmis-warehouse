###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  # Shared defaults for all Hmis::ProjectConfig STI types.
  factory :hmis_project_config_base, class: 'Hmis::ProjectConfig' do
    association :data_source, factory: :hmis_data_source
    created_at { Time.current }
    updated_at { Time.current }

    # Match data source when project or organization is set.
    after(:build) do |config, evaluator|
      config.data_source = evaluator.project.data_source if evaluator.project.present?
      config.data_source = evaluator.organization.data_source if evaluator.organization.present?
    end
  end

  factory :hmis_project_auto_enter_config, parent: :hmis_project_config_base, class: 'Hmis::ProjectAutoEnterConfig' do
  end

  factory :hmis_project_auto_exit_config, parent: :hmis_project_config_base, class: 'Hmis::ProjectAutoExitConfig' do
    config_options { { 'length_of_absence_days': 30 }.to_json }
  end

  factory :hmis_project_staff_assignment_config, parent: :hmis_project_config_base, class: 'Hmis::ProjectStaffAssignmentConfig' do
    association :project, factory: :hmis_hud_project
  end

  factory :hmis_project_ce_config, parent: :hmis_project_config_base, class: 'Hmis::ProjectCeConfig' do
    enabled { true }

    transient do
      receives_direct_referrals { false }
      supports_waitlist_referrals { true }
      receives_direct_referrals_from { nil }
    end

    after(:build) do |config, evaluator|
      options = {}
      options['receives_direct_referrals'] = evaluator.receives_direct_referrals
      options['supports_waitlist_referrals'] = evaluator.supports_waitlist_referrals
      options['receives_direct_referrals_from'] = evaluator.receives_direct_referrals_from if evaluator.receives_direct_referrals_from.present?
      config.config_options = options.to_json
    end
  end

  factory :hmis_project_sends_direct_ce_referrals_config, parent: :hmis_project_config_base, class: 'Hmis::ProjectSendsDirectCeReferralsConfig' do
  end
end
