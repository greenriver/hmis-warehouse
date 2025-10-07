###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
# todo @martha - consider where to move this

# Shared context for CE system tests.
# Sets up a correctly configured target project and admin/provider users with example permissions.
RSpec.shared_context 'ce system test helper' do
  include_context 'hmis base setup'

  let!(:ds1) { GrdaWarehouse::DataSource.find_or_create_by!(hmis: 'localhost', source_type: :sftp, name: 'HMIS', short_name: 'HMIS') }
  let!(:workflow_template) { create(:hmis_workflow_definition_template, data_source: ds1) }

  let!(:target_project) { create(:hmis_hud_project, data_source: ds1, ProjectType: 3, with_coc: true) } # PSH
  let!(:project_ce_config) { create(:hmis_project_ce_config, project: target_project, supports_waitlist_referrals: true, receives_direct_referrals: true) }

  # User setup
  let!(:admin) { create(:hmis_user, data_source: ds1, first_name: 'Alexandra', last_name: 'Admin') }
  let!(:provider) { create(:hmis_user, data_source: ds1, first_name: 'Paul', last_name: 'Provider') }
  let!(:other_user) { create(:hmis_user, data_source: ds1, first_name: 'Oliver', last_name: 'Other') } # user without permissions

  # Simplified permission scenario where admin has all permissions
  let!(:admin_access_control) { create_access_control(admin, ds1) }

  # Provider can see all clients in the data source, but not enrollments
  let!(:provider_datasource_access_control) do
    create_access_control(
      provider,
      ds1,
      with_permission: [
        :can_view_clients,
        :can_view_client_name,
      ],
    )
  end

  # Provider has limited permissions in the project
  let!(:provider_project_access_control) do
    create_access_control(
      provider,
      target_project,
      with_permission: [
        :can_view_project,
        :can_view_enrollment_details,
        :can_edit_enrollments,
        :can_view_units, # but *not* can_manage_units
        :can_update_unit_availability,
        :can_view_own_referrals, # only own (assigned) referrals
        :can_perform_own_referral_tasks,
      ],
    )
  end

  # Eligibility and prioritization fixtures. Note that the rules defined here are not actually used to generate the pool (that's tested elsewhere, outside of system tests).
  # But rules are present anyway so that the waitlist appears correctly in the UI.
  let!(:eligibility_rule) { create(:hmis_ce_match_rule, owner: target_project, rule_type: 'eligibility_requirement', expression: 'cde.custom_assessment.score != NULL AND cde.custom_assessment.score > 5') }
  let!(:priority_rule) { create(:hmis_ce_match_rule, owner: target_project, rule_type: 'priority_scheme', expression: 'cde.custom_assessment.score', priority_rank: 1) }
  let!(:form_definition) { create(:hmis_form_definition, identifier: 'score_assessment', role: :CUSTOM_ASSESSMENT, status: :published, version: 1) }
  let!(:score_cded) { create(:hmis_custom_data_element_definition, owner_type: 'Hmis::Hud::CustomAssessment', form_definition: form_definition, key: :score, label: 'Assessment Score', data_source: ds1) }
  let!(:score_pool) { create :hmis_ce_match_candidate_pool, requirement_expression: 'cde.custom_assessment.score != NULL AND cde.custom_assessment.score > 5', priority_expression: '{cde.custom_assessment.score}' }

  let!(:sro_type) { create(:hmis_unit_type, description: 'SRO') }
  let!(:unit_group) { create(:hmis_unit_group, project: target_project, name: 'SROs', workflow_template: workflow_template, candidate_pool: score_pool) }

  before do
    allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true)
    sign_in(admin) # sign in as admin; use impersonation in tests to complete provider steps
  end
end

RSpec.configure do |rspec|
  rspec.include_context 'ce system test helper', include_shared: true
end
