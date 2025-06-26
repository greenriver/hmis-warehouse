# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProjectGroupsController, type: :request do
  let!(:user) { create(:user) }
  let!(:project_group) { create(:project_group, name: 'Test Group') }
  let!(:project_group_2) { create(:project_group, name: 'Another Group') }
  let!(:role) { create(:role, can_edit_project_groups: true) }
  let!(:data_source) { create(:grda_warehouse_data_source) }
  let!(:organization1) { create(:hud_organization, data_source: data_source) }
  let!(:organization2) { create(:hud_organization, data_source: data_source) }

  let!(:project1) { create(:hud_project, project_name: 'Project 1', data_source: data_source, OrganizationID: organization1.OrganizationID, ProjectType: 1) }
  let!(:project2) { create(:hud_project, project_name: 'Project 2', data_source: data_source, OrganizationID: organization1.OrganizationID, ProjectType: 2) }
  let!(:project3) { create(:hud_project, project_name: 'Project 3', data_source: data_source, OrganizationID: organization2.OrganizationID, ProjectType: 1) }
  let!(:project4) { create(:hud_project, project_name: 'Project 4', data_source: data_source, OrganizationID: organization2.OrganizationID, ProjectType: 3) }

  before(:each) do
    user.legacy_roles << role
    sign_in user
  end

  describe 'GET #index' do
    it 'lists project groups' do
      get project_groups_path
      expect(response).to have_http_status(:success)
      expect(assigns(:project_groups)).to include(project_group, project_group_2)
    end

    it 'filters project groups by search term' do
      get project_groups_path, params: { q: 'Test' }
      expect(response).to have_http_status(:success)
      expect(assigns(:project_groups)).to include(project_group)
      expect(assigns(:project_groups)).not_to include(project_group_2)
    end
  end

  describe 'POST #create' do
    context 'with inclusion and exclusion criteria' do
      let(:form_params) do
        {
          filters: { # expectation that we end up with only projects 1 and 3
            name: 'Test Project Group',
            project_ids: [project1.id, project2.id, project3.id].map(&:to_s),
            organization_ids: [organization1.id].map(&:to_s), # projects 1 and 2
            project_type_numbers: ['1', '2'], # projects 1, 2, and 3
            data_source_ids: [],
            excluded_project_ids: [project2.id].map(&:to_s), # project 2
            excluded_project_type_numbers: ['2'], # project 2
            users: [],
            editor_ids: [user.id],
          },
        }
      end

      it 'creates a project group with correct inclusion and exclusion criteria' do
        expect do
          post project_groups_path, params: form_params
        end.to change(GrdaWarehouse::ProjectGroup, :count).by(1)

        project_group = GrdaWarehouse::ProjectGroup.last

        # Test that the basic attributes are saved
        expect(project_group.name).to eq('Test Project Group')

        # Test inclusion criteria are saved in the filter
        expect(project_group.filter.project_ids).to match_array([project1.id, project2.id, project3.id])
        expect(project_group.filter.organization_ids).to match_array([organization1.id])
        expect(project_group.filter.project_type_numbers).to match_array([1, 2])

        # Test exclusion criteria are saved in the filter
        expect(project_group.filter.excluded_project_ids).to match_array([project2.id])
        expect(project_group.filter.excluded_project_type_numbers).to match_array([2])

        # Test that maintain_projects! was called and projects are properly associated
        expected_project_ids = [project1.id, project3.id]
        expect(project_group.projects.pluck(:id)).to match_array(expected_project_ids)
      end
    end
  end

  describe 'PATCH #update' do
    let!(:project_group) { create(:project_group, name: 'Original Name') }
    let!(:project_group_id) { project_group.id }

    context 'updating inclusion and exclusion criteria' do
      let(:update_params) do
        {
          filters: {
            name: 'Updated Project Group', # expectation that we end up with only project 4
            project_ids: [project1.id, project4.id].map(&:to_s), # projects 1 and 4
            organization_ids: [organization2.id].map(&:to_s), # projects 3 and 4
            project_type_numbers: ['3'], # project 4
            data_source_ids: [],
            excluded_project_ids: [project2.id].map(&:to_s), # project 2
            excluded_project_type_numbers: ['1'], # projects 1 and 3
            users: [],
            editor_ids: [user.id],
          },
        }
      end

      it 'updates the project group with new inclusion and exclusion criteria' do
        patch project_group_path(project_group), params: update_params

        project_group = GrdaWarehouse::ProjectGroup.find(project_group_id)

        # Test that basic attributes are updated
        expect(project_group.name).to eq('Updated Project Group')

        # Test inclusion criteria are updated in the filter
        expect(project_group.filter.project_ids).to match_array([project1.id, project4.id])
        expect(project_group.filter.organization_ids).to match_array([organization2.id])
        expect(project_group.filter.project_type_numbers).to match_array([3])

        # Test exclusion criteria are updated in the filter
        expect(project_group.filter.excluded_project_ids).to match_array([project2.id])
        expect(project_group.filter.excluded_project_type_numbers).to match_array([1])

        # Test that maintain_projects! was called and projects are properly associated
        expected_project_ids = [project4.id]
        expect(project_group.projects.pluck(:id)).to match_array(expected_project_ids)
      end
    end
  end

  describe 'integration with project filtering' do
    let!(:project_group) { create(:project_group, skip_maintain_system_group: true) }

    it 'confirms that inclusion criteria adds projects and exclusion criteria removes them' do
      # Set up initial state with some included projects
      project_group.update(
        options: project_group.filter.update(
          {
            project_ids: [project1.id, project2.id, project3.id],
            excluded_project_ids: [],
          },
        ).to_h,
      )
      project_group.maintain_projects!

      expect(project_group.projects.count).to eq(3)

      # Now add exclusion criteria
      project_group.update(
        options: project_group.filter.update(
          {
            excluded_project_ids: [project2.id],
          },
        ).to_h,
      )
      project_group.maintain_projects!

      # Should now have 2 projects (project2 excluded)
      expect(project_group.projects.count).to eq(2)
      expect(project_group.projects.pluck(:id)).to match_array([project1.id, project3.id])
    end
  end
end
