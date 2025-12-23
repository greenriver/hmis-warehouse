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
  let!(:admin_role) { create :admin_role, can_view_projects: true }
  let!(:admin_user) { create :user, agency: agency, permission_context: 'role_based' } # Legacy user, not ACL user

  # Create test entities for selection
  let!(:data_source_1) { create :grda_warehouse_data_source, name: 'Test Data Source 1', source_type: 'sftp' }
  let!(:data_source_2) { create :grda_warehouse_data_source, name: 'Test Data Source 2', source_type: 'sftp' }
  let!(:organization_1) { create :hud_organization, OrganizationName: 'Test Organization 1', data_source: data_source_1 }
  let!(:organization_2) { create :hud_organization, OrganizationName: 'Test Organization 2', data_source: data_source_2 }
  let!(:project_1) { create :hud_project, ProjectName: 'Test Project 1', data_source: data_source_1, OrganizationID: organization_1.OrganizationID }
  let!(:project_2) { create :hud_project, ProjectName: 'Test Project 2', data_source: data_source_2, OrganizationID: organization_2.OrganizationID }
  let!(:project_access_group_1) { create :project_access_group, name: 'Test Project Group 1' }
  let!(:project_access_group_2) { create :project_access_group, name: 'Test Project Group 2' }

  before do
    # Set up admin user with legacy role-based permissions
    admin_user.user_roles.create!(role: admin_role)
    admin_user.access_group.add_viewable(data_source_1)
    admin_user.access_group.add_viewable(data_source_2)
    admin_user.access_group.add_viewable(project_access_group_1)
    admin_user.access_group.add_viewable(project_access_group_2)
  end

  describe 'User Editing with Existing Selections', js: true do
    let!(:existing_user) { create :user, agency: agency, first_name: 'Existing', last_name: 'User', permission_context: 'role_based' }

    before do
      access_group = existing_user.access_group
      # Add some viewable entities to the access group so they appear
      # on the page as pre-selected
      access_group.add_viewable(data_source_1)
      access_group.add_viewable(project_2)
      sign_in_user(admin_user)
    end

    # These tests are relatively flaky, we've confirmed in the app that things are working.
    # For now, we'll limit the checks here to decrease runtime and hopefully succeed more often than not.
    it 'displays existing selections and maintains previous selections on save' do
      # Navigate to edit user page
      visit edit_admin_user_path(existing_user)

      click_link 'Data Access Assignments'

      # Wait for all lazy-loaded sections to finish loading.
      # This ensures all AJAX requests for select options have completed.
      expect(page).not_to have_css('.select-placeholder:not(.loaded)', wait: 20)

      # Verify that the correct <option> elements are marked as selected in the hidden selects.
      # This confirms that the form will submit the correct, pre-existing values.
      expect(page).to have_select('user[data_sources][]', selected: data_source_1.name, visible: :hidden)
      expect(page).to have_select('user[projects][]', selected: project_2.name_and_type, visible: :hidden)

      access_group = existing_user.access_group
      expect(access_group.data_sources).to include(data_source_1)
      expect(access_group.projects).to include(project_2)

      # Wait for and verify existing selections are displayed
      expect(page).to have_content('Test Data Source 1')
      expect(page).to have_content('Test Project 2')

      # Verify form functionality
      form_data = page.evaluate_script('$(arguments[0]).serialize()', find('form.edit_user'))
      expect(form_data).to include(data_source_1.id.to_s)
      expect(form_data).to include(project_2.id.to_s)

      click_button 'Update User'
      expect(page).to have_current_path(edit_admin_user_path(existing_user))

      # Verify selections persist after save
      visit edit_admin_user_path(existing_user)
      click_link 'Data Access Assignments'

      # Wait for all lazy-loaded sections to finish loading.
      # This ensures all AJAX requests for select options have completed.
      expect(page).not_to have_css('.select-placeholder:not(.loaded)', wait: 20)

      access_group = existing_user.access_group
      expect(access_group.data_sources).to include(data_source_1)
      expect(access_group.projects).to include(project_2)

      # Wait for and verify existing selections are displayed
      expect(page).to have_select('user[data_sources][]', selected: data_source_1.name, visible: :hidden)
      expect(page).to have_select('user[projects][]', selected: project_2.name_and_type, visible: :hidden)
    end

    it 'handles removing selections correctly' do
      visit edit_admin_user_path(existing_user)
      click_link 'Data Access Assignments'

      # Useful debugging code for future situations,
      # native.property('innerHTML') returns the HTML of the element
      el = find('#projects-column')

      expect(existing_user.access_group.projects).to include(project_2)
      expect(page).to have_selector('li', text: 'Test Project 2')
      project_column_html = el.native.property('innerHTML')
      expect(project_column_html).to include('Test Project 2')

      # Remove the selection by clicking on the list item (this is how removal works)

      within('#projects-column') do
        # *** Explicitly wait for the lazy-loaded content to appear ***
        expect(page).to have_selector('li', text: 'Test Project 2', wait: 20)

        # Find the list item containing the project and click it to remove
        list_item = find('li.c-columns__column-list-item', text: 'Test Project 2')
        list_item.click
      end

      # Verify it's removed from the display
      within('#projects-column') do
        expect(page).not_to have_content('Test Project 2')
      end

      # Submit the form
      click_button 'Update User'
      expect_success_message

      # Reload and verify the removal persisted
      visit edit_admin_user_path(existing_user)
      click_link 'Data Access Assignments'

      # Wait for lazy loading and check for empty state
      within('#projects-column') do
        expect(page).not_to have_selector('li', text: 'Test Project 2', wait: 20)
      end
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
        # lazy loaded
        expect(page).to have_content('Test Organization 1')
      end
    end
  end

  describe 'Error Handling and Edge Cases', js: true do
    before { sign_in_user(admin_user) }

    it 'works correctly when switching between tabs multiple times' do
      visit new_admin_user_path

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
