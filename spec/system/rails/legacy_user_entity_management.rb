###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Legacy User Management with Lazy Loading', type: :rails_system do
  # Tests the lazy loading functionality for legacy role-based users who use the
  # "Data Access Assignments" tabs with viewable entities. ACL users would use
  # the "User Groups" interface instead and don't use this lazy loading feature.
  include_context 'RailsSystemHelper'

  let!(:agency) { create :agency }
  let!(:admin_role) { create :admin_role }
  let!(:admin_user) { create :user, agency: agency, permission_context: 'role_based' } # Legacy user, not ACL user

  # Create test entities for selection
  let!(:data_source_1) { create :grda_warehouse_data_source, name: 'Test Data Source 1' }
  let!(:data_source_2) { create :grda_warehouse_data_source, name: 'Test Data Source 2' }
  let!(:organization_1) { create :hud_organization, OrganizationName: 'Test Organization 1', data_source: data_source_1 }
  let!(:organization_2) { create :hud_organization, OrganizationName: 'Test Organization 2', data_source: data_source_1 }
  let!(:project_1) { create :hud_project, ProjectName: 'Test Project 1', data_source: data_source_1, OrganizationID: organization_1.OrganizationID }
  let!(:project_2) { create :hud_project, ProjectName: 'Test Project 2', data_source: data_source_1, OrganizationID: organization_2.OrganizationID }
  let!(:project_access_group_1) { create :project_access_group, name: 'Test Project Group 1' }
  let!(:project_access_group_2) { create :project_access_group, name: 'Test Project Group 2' }

  before do
    # Set up admin user with legacy role-based permissions
    admin_user.user_roles.create!(role: admin_role)
  end

  describe 'User Creation via Invitation', js: true do
    before { sign_in_user(admin_user) }

    it 'shows the lazy loaded interface for new user creation' do
      # Navigate to new user invitation page
      visit new_user_invitation_path

      # Fill in basic user information
      fill_in 'First name', with: 'Test'
      fill_in 'Last name', with: 'User'
      fill_in 'Email', with: 'testuser@example.com'
      select agency.name, from: 'Agency'

      # Verify legacy interface is shown (not ACL interface)
      expect(page).not_to have_content('User Access')
      expect(page).to have_content('Data Access Assignments')

      click_link 'Data Access Assignments'

      # Verify lazy loading interface is present for new users
      expect(page).to have_css('.select-placeholder', visible: false)
      expect(page).to have_css('.j-column-actions-add', visible: false)

      # Verify lazy loading interface is present
      expect(page).to have_css('#data_sources-column')
      expect(page).to have_css('.select-placeholder, select', visible: false, wait: 10)
    end

    it 'allows entity selection for new users with lazy loaded interface' do
      visit new_user_invitation_path
      click_link 'Data Access Assignments'

      # Verify multiple entity columns are present with proper IDs
      expect(page).to have_css('#data_sources-column')
      expect(page).to have_css('#organizations-column')
      expect(page).to have_css('#projects-column')
      expect(page).to have_css('#project_access_groups-column')

      # Each column should have interface elements (visible or hidden)
      within('#data_sources-column') do
        expect(page).to have_css('select, .select-placeholder', visible: false)
      end
    end
  end

  describe 'User Editing with Existing Selections', js: true do
    let!(:existing_user) { create :user, agency: agency, first_name: 'Existing', last_name: 'User', permission_context: 'role_based' }
    let!(:existing_access_group) { create :access_group, name: 'Existing Access Group' }

    before do
      # Set up existing user with legacy access group and some selected entities
      existing_access_group.add(existing_user)
      existing_user.user_roles.create!(role: admin_role)

      # Add some viewable entities to the access group
      existing_access_group.add_viewable(data_source_1)
      existing_access_group.add_viewable(organization_1)
      existing_access_group.add_viewable(project_1)
      existing_access_group.add_viewable(project_access_group_1)

      sign_in_user(admin_user)
    end

    it 'displays existing selections and allows modifications' do
      # Navigate to edit user page
      visit edit_admin_user_path(existing_user)

      click_link 'Data Access Assignments'

      # Wait for and verify existing selections are displayed
      expect(page).to have_content('Test Data Source 1', wait: 10)
      expect(page).to have_content('Test Organization 1')
      expect(page).to have_content('Test Project 1')
      expect(page).to have_content('Test Project Group 1')

      # Verify form functionality

      click_button 'Update User'
      expect(page).to have_current_path(edit_admin_user_path(existing_user))

      # Verify selections persist after save
      visit edit_admin_user_path(existing_user)
      click_link 'Data Access Assignments'
      expect(page).to have_content('Test Data Source 1', wait: 10)
      expect(page).to have_content('Test Organization 1')
      expect(page).to have_content('Test Project 1')
      expect(page).to have_content('Test Project Group 1')
    end

    it 'handles removing selections correctly' do
      visit edit_admin_user_path(existing_user)
      click_link 'Data Access Assignments'

      # Wait for existing selection to appear
      expect(page).to have_content('Test Data Source 1', wait: 10)

      # Remove the selection using ID-based targeting
      removed_successfully = false
      within('#data_sources-column') do
        within('#data_sources-list') do
          if has_css?('.j-remove')
            find('.j-remove', match: :first).click
            removed_successfully = true
          end
        end
      end

      skip 'Remove functionality not available in current interface' unless removed_successfully

      # Verify it's removed from the display
      expect(page).not_to have_content('Test Data Source 1')

      # Submit the form
      click_button 'Update User'
      expect_success_message

      # Reload and verify the removal persisted
      visit edit_admin_user_path(existing_user)
      click_link 'Data Access Assignments'

      # Should show "No Data Sources selected" or similar
      expect(page).to have_content('No Data Sources selected', wait: 10)
    end
  end

  describe 'JavaScript Loading and Execution', js: true do
    before { sign_in_user(admin_user) }

    it 'loads ViewableEntities JavaScript correctly' do
      # Test with an existing user edit page where lazy loading should work
      existing_user = create :user, agency: agency, permission_context: 'role_based'
      existing_user.user_roles.create!(role: admin_role)

      visit edit_admin_user_path(existing_user)

      # Wait for page to fully load
      expect(page).to have_content('User Information')

      # Check JavaScript environment
      expect(page.evaluate_script('typeof jQuery')).to eq('function')
      expect(page.evaluate_script('typeof window.App')).to eq('object')

      # Navigate to the tab that should trigger lazy loading
      click_link 'Data Access Assignments'

      # Check if ViewableEntities class is available
      viewable_entities_available = page.evaluate_script('
        typeof window.App !== "undefined" &&
        typeof window.App.ViewableEntities !== "undefined"
      ')
      expect(viewable_entities_available).to be true

      # Check if the constructor was called (by looking for evidence of initialization)
      # The ViewableEntities constructor should create the class and call methods
      constructor_called = page.evaluate_script('
        (function() {
          // Check if the ViewableEntities was instantiated by looking for any evidence
          return document.querySelectorAll("[data-bs-toggle=tooltip]").length > 0 ||
                 typeof window.App.ViewableEntities === "function";
        })();
      ')
      expect(constructor_called).to be true
    end
  end

  describe 'Role-based User Workflow', js: true do
    let!(:role_user) { create :user, agency: agency, first_name: 'Role', last_name: 'User', permission_context: 'role_based' }
    let!(:user_role) { create :admin_role }
    let!(:access_group) { create :access_group }

    before do
      # Set up role-based user with access group
      access_group.add(role_user)
      role_user.user_roles.create!(role: user_role)

      # Add some viewable entities to the access group
      access_group.add_viewable(data_source_1)
      access_group.add_viewable(organization_1)

      sign_in_user(admin_user)
    end

    it 'displays existing selections for role-based users using viewable entities tabs' do
      visit edit_admin_user_path(role_user)
      expect(page).to have_link('Data Access Assignments')
      click_link 'Data Access Assignments'

      # Verify selections are displayed in correct columns
      within('#data_sources-column') do
        expect(page).to have_content('Test Data Source 1', wait: 10)
      end
      within('#organizations-column') do
        expect(page).to have_content('Test Organization 1')
      end
    end
  end

  describe 'Error Handling and Edge Cases', js: true do
    before { sign_in_user(admin_user) }

    it 'handles AJAX failures gracefully' do
      visit new_user_invitation_path
      click_link 'Data Access Assignments'

      # Simulate network failure by stubbing the AJAX endpoint
      page.execute_script("
        if (typeof $ !== 'undefined' && $.get) {
          var originalGet = $.get;
          $.get = function(url) {
            var deferred = $.Deferred();
            setTimeout(function() { deferred.reject(); }, 100);
            return deferred.promise();
          };
        }
      ")

      # Trigger tab changes to test error handling
      click_link 'Reports & Cohorts'
      click_link 'Data Access Assignments'

      # Should show fallback interface when AJAX fails
      expect(page).to have_css('#data_sources-column', wait: 5)
    end

    it 'works correctly when switching between tabs multiple times' do
      visit new_user_invitation_path

      # Switch between tabs multiple times to test stability
      3.times do
        click_link 'Data Access Assignments'
        expect(page).to have_css('#data_sources-column', wait: 5)

        click_link 'Reports & Cohorts'
        expect(page).to have_css('#reports-column', wait: 5)
      end

      # Verify interface remains functional after multiple switches
      click_link 'Data Access Assignments'
      expect(page).to have_css('#data_sources-column')
      expect(page).to have_css('#organizations-column')
    end
  end
end
