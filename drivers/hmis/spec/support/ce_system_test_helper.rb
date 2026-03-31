###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# Shared context for CE system tests.
# Sets up a correctly configured target project and admin/provider users with example permissions.
RSpec.shared_context 'ce system test helper' do
  # Use find_by! since rails_helper creates the data source in a before(:all) block for performance reasons.
  let!(:ds1) { GrdaWarehouse::DataSource.hmis.find_by!(hmis: 'localhost') }

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

  # Eligibility and prioritization fixtures.
  # These rules are not actually used to generate the pool (that's tested elsewhere, outside of system tests).
  # But rules must be present so that the waitlist appears correctly in the UI.
  let!(:eligibility_rule) { create(:hmis_ce_match_rule, owner: target_project, rule_type: 'eligibility_requirement', expression: 'cde.custom_assessment.score != NULL AND cde.custom_assessment.score > 5') }
  let!(:priority_rule) { create(:hmis_ce_match_rule, owner: target_project, rule_type: 'priority_scheme', expression: 'cde.custom_assessment.score', priority_rank: 1) }
  let!(:form_definition) { create(:hmis_form_definition, identifier: 'score_assessment', role: :CUSTOM_ASSESSMENT, status: :published, version: 1) }
  let!(:score_cded) { create(:hmis_custom_data_element_definition, owner_type: 'Hmis::Hud::CustomAssessment', form_definition: form_definition, key: :score, label: 'Assessment Score', data_source: ds1) }
  let!(:score_pool) { create :hmis_ce_match_candidate_pool, requirement_expression: 'cde.custom_assessment.score != NULL AND cde.custom_assessment.score > 5', priority_expression: '{cde.custom_assessment.score}' }

  let!(:sro_type) { create(:hmis_unit_type, description: 'SRO') }
  let!(:workflow_template) { create(:hmis_workflow_definition_template, data_source: ds1) }
  let!(:unit_group) { create(:hmis_unit_group, project: target_project, name: 'SROs', workflow_template: workflow_template, candidate_pool: score_pool, unit_type: sro_type) }

  before do
    allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true)
    sign_in(admin) # sign in as admin; use impersonation in tests to complete provider steps
  end

  # Shared helper for completing a CE step. Yields to the block to allow for filling in custom fields.
  def complete_ce_step(step_name)
    click_button "Start step: #{step_name}"
    expect(page).to have_content('Back to All Tasks')
    begin
      yield
    ensure
      click_button 'Submit'
    end
  end

  # Shared helper for assigning referral steps.
  # assignment_map is a hashmap { swimlane_name => [user_name] }
  def assign_referral_contacts(assignment_map)
    expect(page).to have_content('No assigned users')

    # Assign provider to the Provider Outcome step
    click_button 'Contacts'
    assignment_map.each do |swimlane, users|
      users.each do |user|
        mui_select(user, from: swimlane)
      end
    end

    click_button 'Submit'
    expect(page).not_to have_content('No assigned users')
    expect(page).to have_content("Assigned to #{assignment_map.values.first.first}")
  end

  def with_referral_panel_open(panel_name)
    click_button panel_name
    begin
      yield
    ensure
      click_button 'close'
    end
  end

  def add_referral_note(note_text: nil)
    note_text ||= 'Hello, this is a note'
    click_button 'Add Note'
    fill_in 'Note', with: note_text
    click_button 'Submit Note'
    expect(page).to have_content("Note #{note_text}")
  end
end

RSpec.configure do |rspec|
  rspec.include_context 'ce system test helper', include_shared: true
end
