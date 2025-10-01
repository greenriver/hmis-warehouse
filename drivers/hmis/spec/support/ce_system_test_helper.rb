# frozen_string_literal: true

require 'rails_helper'
require_relative '../requests/hmis/login_and_permissions'

RSpec.shared_context 'ce system test helper' do
  include_context 'hmis base setup'

  let!(:ds1) { create(:hmis_data_source, hmis: 'localhost') }
  let!(:p1) { create(:hmis_hud_project, data_source: ds1, ProjectType: 3) } # PSH

  let!(:admin) { create(:hmis_user, data_source: ds1, first_name: 'Alexandra', last_name: 'Admin') }
  let!(:provider) { create(:hmis_user, data_source: ds1, first_name: 'Paul', last_name: 'Provider') }
  let!(:other_user) { create(:hmis_user, data_source: ds1, first_name: 'Oliver', last_name: 'Other') } # user without permissions

  # Simplified permission scenario where admin has all permissions
  let!(:admin_ac) { create_access_control(admin, ds1) }
  let!(:provider_ac) do
    create_access_control(
      provider,
      ds1,
      with_permission: [
        :can_view_project,
        :can_view_clients,
        :can_view_units, # but *not* can_manage_units
        :can_update_unit_availability,
        :can_view_own_referrals,
        :can_perform_own_referral_tasks,
      ],
    )
  end

  before do
    allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true)
    HmisUtil::JsonForms.new(env_key: 'allegheny', override_generate_cdeds_in_test: true).seed_record_form_definitions(roles: [:CE_REFERRAL_STEP])
    CeWorkflows::Shared::CeBuilderUtils.create_state_machine_custom_statuses(ds1)
  end

  let!(:workflow_template) { CeWorkflows::Ac::WorkflowBuilder.new(ds1).build_housing_workflow }
  let!(:coc1) { create :hmis_hud_project_coc, data_source: ds1, project: p1, coc_code: 'CO-500' }
  let!(:eligibility_rule) { create(:hmis_ce_match_rule, owner: p1, rule_type: 'eligibility_requirement', expression: 'cde.custom_assessment.score != NULL AND cde.custom_assessment.score > 5') }
  let!(:priority_rule) { create(:hmis_ce_match_rule, owner: p1, rule_type: 'priority_scheme', expression: 'cde.custom_assessment.score', priority_rank: 1) }
  let!(:form_definition) { create(:hmis_form_definition, identifier: 'score_assessment', role: :CUSTOM_ASSESSMENT, status: :published, version: 1) }
  let!(:score_cded) { create(:hmis_custom_data_element_definition, owner_type: 'Hmis::Hud::CustomAssessment', form_definition: form_definition, key: :score, label: 'Assessment Score', data_source: ds1) }
  let!(:score_pool) { create :hmis_ce_match_candidate_pool, requirement_expression: 'cde.custom_assessment.score != NULL AND cde.custom_assessment.score > 5', priority_expression: '{cde.custom_assessment.score}' }

  let!(:sro_type) { create(:hmis_unit_type, description: 'SRO') }
  let!(:unit_group) { create(:hmis_unit_group, project: p1, name: 'SROs', workflow_template: workflow_template, candidate_pool: score_pool) }
  let!(:project_ce_config) { create(:hmis_project_ce_config, project: p1, supports_waitlist_referrals: true) }

  before(:each) do
    sign_in(admin) # sign in as admin, impersonate provider
  end
end

RSpec.configure do |rspec|
  rspec.include_context 'ce system test helper', include_shared: true
end
