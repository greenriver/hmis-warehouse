###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: false

require 'rails_helper'
require_relative '../../requests/hmis/login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.feature 'CE Direct Referrals', type: :system do
  include_context 'ce system test helper'

  let!(:source_project) { create(:hmis_hud_project, data_source: ds1, ProjectType: 14) } # Coordinated Entry
  let!(:target_project) { create(:hmis_hud_project, data_source: ds1, ProjectType: 1) } # Emergency Shelter
  let!(:coc1) { create :hmis_hud_project_coc, data_source: ds1, project: target_project, coc_code: 'CO-500' }

  # Set up target project for receiving direct referrals
  let!(:workflow_template) { CeWorkflows::Ac::WorkflowBuilder.new(ds1).build_admin_assign_workflow }
  let!(:unit_group) { create(:hmis_unit_group, project: target_project, workflow_template: workflow_template) }
  let!(:unit) { create(:hmis_unit, project: target_project, unit_type: sro_type, unit_group: unit_group) }
  let!(:opportunity) { create(:hmis_ce_opportunity, project: target_project, workflow_template: workflow_template, unit: unit, name: unit.name) }
  let!(:target_project_ce_config) { create(:hmis_project_ce_config, project: target_project, receives_direct_referrals: true) }

  # Set up source project for sending direct referrals
  let!(:source_project_ce_config) { create(:hmis_project_sends_direct_ce_referrals_config, project: source_project) }

  # Create client with enrollment in source project
  let!(:client1) { create(:hmis_hud_client_with_warehouse_client, data_source: ds1, first_name: 'Dan', last_name: 'D') }
  let!(:source_enrollment) { create(:hmis_hud_enrollment, data_source: ds1, project: source_project, client: client1, entry_date: 30.days.ago) }

  # Create household member for testing household referrals
  let!(:household_member) { create(:hmis_hud_client_with_warehouse_client, data_source: ds1, first_name: 'Jane', last_name: 'D') }
  let!(:household_enrollment) { create(:hmis_hud_enrollment, data_source: ds1, project: p1, client: household_member, entry_date: 30.days.ago, household_id: source_enrollment.household_id, relationship_to_ho_h: 2) }

  let!(:provider_global_ac) do
    create_access_control(
      provider,
      ds1,
      with_permission: [
        :can_view_clients,
        :can_view_client_name,
        :can_view_limited_enrollment_details,
      ],
    )
  end

  let!(:provider_ac) do
    create_access_control(
      provider,
      target_project,
      with_permission: [
        :can_view_project,
        :can_view_enrollment_details,
        :can_edit_enrollments,
        :can_view_own_referrals,
        :can_perform_own_referral_tasks,
      ],
    )
  end

  # Shared method for creating a direct referral
  def create_direct_referral
    # Navigate to source project and find the enrollment
    visit "/projects/#{source_project.id}/referrals"
    click_link 'Send Referral'
    mui_select('Dan D and 1 other', from: 'HoH Enrollment')
    mui_select(target_project.project_name, from: 'Project')
    mui_select(unit_group.name, from: 'Unit Group')
    fill_in 'Resource Coordinator Notes', with: 'Direct referral for Dan D to Family Shelter'
    click_button 'Refer Household'
    expect(page).to have_content('Displaying 1 of 1 outgoing referral')

    Hmis::Ce::Referral.last
  end

  # Shared method for assigning provider to referral
  def assign_provider_to_referral(referral)
    visit("/projects/#{target_project.id}/ce/referrals/#{referral.id}")

    expect(page).to have_content('Referral for Dan D')

    # Assign provider to the Provider Outcome step
    expect(page).to have_content('Provider Outcome Available Today Project Staff No assigned users')
    click_button 'Contacts'
    mui_select('Paul Provider', from: 'Project Staff')
    click_button 'Submit'
    expect(page).not_to have_content('No assigned users')
    expect(page).to have_content('Assigned to Paul Provider')
  end

  it 'completes the direct referral happy path' do
    # Create the direct referral
    referral = create_direct_referral
    expect(referral.status).to eq('in_progress')
    expect(referral.client).to eq(client1)
    expect(referral.referred_by).to eq(admin)
    expect(referral.referral_origin).to eq('direct_send')
    expect(referral.source_enrollment).to eq(source_enrollment)
    # Assign provider to the referral
    assign_provider_to_referral(referral)
    # Provider opens referral and completes the Provider Outcome task
    with_user_impersonated('Paul Provider') do
      # Provider can view the referral from their dashboard
      click_link 'Dashboard'
      expect(page).to have_content('PAUL PROVIDER HMIS Dashboard')
      expect(page).to have_content('Dan D')
      # Provider can view the referral from the project referrals table
      visit "/projects/#{target_project.id}/ce#referrals"
      expect(page).to have_content('Displaying 1 of 1 referral')
      expect(page).to have_content('Dan D')
      expect(page).to have_content('Assigned')
      click_link 'Dan D'
      # Provider can see the previously completed Admin Assign task
      click_link 'View step: Admin Assign'
      expect(page).to have_content('Direct referral for Dan D to Family Shelter')
      click_link 'Back to All Tasks'
      # Provider can see Details panel
      click_button 'Details'
      find("[role='button']", text: 'Source Enrollment Details').click # Can view enrollment details
      expect(page).to have_content('Household Members')
      expect(page).to have_content('Dan D (HoH)') # Head of household
      expect(page).to have_content('Jane D (Child)') # Household member
      click_button 'close'
      # Provider accepts the referral
      expect(page).to have_content('Provider Outcome Available Today Assigned to you')
      click_button 'Start step: Provider Outcome'
      mui_date_select 'Date', date: Date.current
      fill_in 'Notes', with: 'Provider accepts direct referral'
      mui_radio_choose 'Accept - Add to Project', from: 'Decision'
      expect(page).to have_content('The client will be added to the project as Incomplete.')
      click_button 'Submit'
      # Confirm Success task is available but provider can't access it
      expect(page).to have_content('Confirm Success Available Today')
      expect(page).not_to have_button('Start step: Confirm Success')
      # Target enrollment was created
      target_enrollment = referral.reload.target_enrollment
      expect(target_enrollment).to be_present
      expect(target_enrollment.project).to eq(target_project)
      expect(target_enrollment.current_unit).to eq(unit)

      # CE Staff can add household members to the target enrollment
      visit "/client/#{client1.id}/enrollments/#{target_enrollment.id}/household"
      find("[role='button']", text: 'Add Household Member').click
      # todo @martha - associated household members are not visible due to provider permissions, if I have that configured correctly
      fill_in 'Search for Client', with: 'Jane D'
      click_button 'Search'
      click_button 'Add to Household'
      mui_select 'Child', from: 'Relationship to HoH'
      click_button 'Enroll'
      expect(page).to have_content('Jane D')
      # todo @martha - added household member is not assigned to the unit. but in real life it would be due to form configs
    end
    # CE Staff completes the Confirm Success step
    visit("/projects/#{target_project.id}/ce/referrals/#{referral.id}")
    click_button 'Start step: Confirm Success'
    mui_date_select 'Date', date: Date.current
    fill_in 'Notes', with: 'Direct referral completed successfully'
    click_button 'Submit'
    expect(page).to have_content('Referral Complete')
    expect(page).to have_content("Dan D has been accepted to #{unit.name}")
    expect(referral.reload.status).to eq('accepted')
    # CE event was created on source enrollment
    event = referral.source_enrollment.events.sole
    expect(event.event).to eq(10) # referral to ES event type
    expect(event.location_crisis_or_ph_housing).to eq(target_project.id.to_s)
    expect(event.referral_result).to eq(1) # successful referral: client accepted
  end
end
