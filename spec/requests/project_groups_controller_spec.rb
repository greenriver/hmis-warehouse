###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProjectGroupsController, type: :request do
  include AccessControlSetup

  let!(:user) { create(:user) }
  let!(:project_group) { create(:project_group, name: 'Test Group') }
  let!(:project_group_2) { create(:project_group, name: 'Another Group') }
  let!(:role) { create(:role, can_edit_project_groups: true, can_view_projects: true) }
  let!(:data_source) { create(:grda_warehouse_data_source) }
  let!(:organization1) { create(:hud_organization, data_source: data_source) }
  let!(:organization2) { create(:hud_organization, data_source: data_source) }

  let!(:project1) { create(:hud_project, project_name: 'Project 1', data_source: data_source, OrganizationID: organization1.OrganizationID, ProjectType: 1) }
  let!(:project2) { create(:hud_project, project_name: 'Project 2', data_source: data_source, OrganizationID: organization1.OrganizationID, ProjectType: 2) }
  let!(:project3) { create(:hud_project, project_name: 'Project 3', data_source: data_source, OrganizationID: organization2.OrganizationID, ProjectType: 1) }
  let!(:project4) { create(:hud_project, project_name: 'Project 4', data_source: data_source, OrganizationID: organization2.OrganizationID, ProjectType: 3) }

  before(:each) do
    user.legacy_roles << role
    # the form only saves projects, organizations, and data sources the editor can see
    user.access_group.add_viewable(data_source)
    user.clear_memery_cache!
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

    it 'displays notes in the response' do
      create(:project_group, name: 'Notes Group', notes: 'Visible note text')
      get project_groups_path
      expect(response.body).to include('Visible note text')
    end
  end

  describe 'POST #create' do
    context 'with inclusion and exclusion criteria' do
      let(:form_params) do
        {
          filters: { # expectation that we end up with only projects 1 and 3
            name: 'Test Project Group',
            notes: 'Some notes',
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
        expect(project_group.notes).to eq('Some notes')

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
            notes: 'Updated notes',
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
        expect(project_group.notes).to eq('Updated notes')

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

  describe 'deleting project groups' do
    it "DELETE #destroy removes the project group's system collection" do
      collection = project_group.editable_access_control.collection # project groups support editable only

      delete project_group_path(project_group)

      expect(response).to redirect_to(project_groups_path)
      expect(GrdaWarehouse::ProjectGroup.find_by(id: project_group.id)).to be_nil
      expect(Collection.find_by(id: collection.id)).to be_nil
    end

    it "delete_multiple removes each project group's system collection" do
      collection_1 = project_group.editable_access_control.collection
      collection_2 = project_group_2.editable_access_control.collection

      post delete_multiple_project_groups_path, params: { selections: { group: [project_group.id.to_s, project_group_2.id.to_s] } }

      expect(response).to redirect_to(project_groups_path)
      expect(GrdaWarehouse::ProjectGroup.find_by(id: project_group.id)).to be_nil
      expect(GrdaWarehouse::ProjectGroup.find_by(id: project_group_2.id)).to be_nil
      expect(Collection.find_by(id: collection_1.id)).to be_nil
      expect(Collection.find_by(id: collection_2.id)).to be_nil
    end

    it 'delete_multiple does not delete project groups that were not selected' do
      selected_collection = project_group.editable_access_control.collection
      unselected = create(:project_group, name: 'Keep Me')
      unselected_collection = unselected.editable_access_control.collection

      post delete_multiple_project_groups_path, params: { selections: { group: [project_group.id.to_s] } }

      # selected group is torn down...
      expect(GrdaWarehouse::ProjectGroup.find_by(id: project_group.id)).to be_nil
      expect(Collection.find_by(id: selected_collection.id)).to be_nil
      # ...but an unselected group and its collection survive
      expect(GrdaWarehouse::ProjectGroup.find_by(id: unselected.id)).to be_present
      expect(Collection.find_by(id: unselected_collection.id)).to be_present
    end

    it 'delete_multiple with no selection redirects without deleting anything' do
      collection = project_group.editable_access_control.collection

      post delete_multiple_project_groups_path

      expect(response).to redirect_to(project_groups_path)
      expect(GrdaWarehouse::ProjectGroup.find_by(id: project_group.id)).to be_present
      expect(Collection.find_by(id: collection.id)).to be_present
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

  describe 'delete guard' do
    let!(:collection) { project_group.editable_access_control.collection }

    shared_examples 'a group that cannot be deleted' do
      it 'DELETE #destroy leaves the group in place' do
        delete project_group_path(project_group)

        expect(response).to redirect_to(edit_project_group_path(project_group))
        expect(flash[:error]).to include(project_group.name)
        expect(GrdaWarehouse::ProjectGroup.find_by(id: project_group.id)).to be_present
        expect(Collection.find_by(id: collection.id)).to be_present
      end

      it 'delete_multiple skips the group, deletes the others, and flashes the skipped name' do
        post delete_multiple_project_groups_path, params: { selections: { group: [project_group.id.to_s, project_group_2.id.to_s] } }

        expect(response).to redirect_to(project_groups_path)
        expect(flash[:error]).to include(project_group.name)
        expect(flash[:error]).not_to include(project_group_2.name)
        expect(GrdaWarehouse::ProjectGroup.find_by(id: project_group.id)).to be_present
        expect(Collection.find_by(id: collection.id)).to be_present
        expect(GrdaWarehouse::ProjectGroup.find_by(id: project_group_2.id)).to be_nil
      end
    end

    context 'when the group populates a cohort' do
      before { create(:cohort, project_group_id: project_group.id) }

      it_behaves_like 'a group that cannot be deleted'
    end

    context 'when the group is used for CAS sync' do
      before do
        GrdaWarehouse::Config.first_or_create.update!(
          cas_available_method: 'project_group',
          cas_sync_project_group_id: project_group.id,
        )
      end

      after { GrdaWarehouse::Config.invalidate_cache }

      it_behaves_like 'a group that cannot be deleted'
    end
  end

  describe 'restricted editors' do
    let!(:other_data_source) { create(:grda_warehouse_data_source, short_name: 'HiddenSourceDS') }
    let!(:visible_organization) { create(:hud_organization, data_source: data_source, OrganizationName: 'Visible Org') }
    let!(:hidden_organization) { create(:hud_organization, data_source: other_data_source, OrganizationName: 'Hidden Org XYZ') }
    let!(:visible_project) do
      create(:hud_project, ProjectName: 'Visible Project ABC', data_source: data_source, OrganizationID: visible_organization.OrganizationID, ProjectType: 1)
    end
    let!(:confidential_project) do
      create(:hud_project, ProjectName: 'Secret Shelter QRS', confidential: true, data_source: data_source, OrganizationID: visible_organization.OrganizationID, ProjectType: 1)
    end
    let!(:hidden_project) do
      create(:hud_project, ProjectName: 'Out Of Scope Project DEF', data_source: other_data_source, OrganizationID: hidden_organization.OrganizationID, ProjectType: 1)
    end
    let!(:excluded_hidden_project) do
      create(:hud_project, ProjectName: 'Excluded Hidden GHI', data_source: other_data_source, OrganizationID: hidden_organization.OrganizationID, ProjectType: 1)
    end
    let!(:assigned_group) do
      group = create(:project_group, name: 'Assigned Group')
      group.update!(
        options: group.filter.update(
          project_ids: [visible_project.id, confidential_project.id, hidden_project.id],
          organization_ids: [hidden_organization.id],
          data_source_ids: [other_data_source.id],
          excluded_project_ids: [excluded_hidden_project.id],
        ).to_h,
      )
      group.maintain_projects!
      group
    end

    it 'the group includes all three projects regardless of who views it' do
      expect(assigned_group.projects).to contain_exactly(visible_project, confidential_project, hidden_project)
    end

    shared_examples 'a restricted editor' do
      it 'returns 404 on edit for an unassigned group' do
        get edit_project_group_path(project_group_2)
        expect(response).to have_http_status(:not_found)
      end

      it 'returns 404 on update for an unassigned group and leaves it unchanged' do
        patch project_group_path(project_group_2), params: { filters: { name: 'Hijacked', notes: 'x', project_ids: [], editor_ids: [], users: [] } }

        expect(response).to have_http_status(:not_found)
        expect(project_group_2.reload.name).to eq('Another Group')
      end

      it 'returns 404 on destroy for an unassigned group and leaves it in place' do
        delete project_group_path(project_group_2)

        expect(response).to have_http_status(:not_found)
        expect(GrdaWarehouse::ProjectGroup.find_by(id: project_group_2.id)).to be_present
      end

      it 'returns 404 on delete_multiple with an unassigned group and deletes neither group' do
        assigned_collection = assigned_group.editable_access_control.collection
        unassigned_collection = project_group_2.editable_access_control.collection
        # assigned group first, so it is destroyed before the unassigned lookup fails
        selected_ids = [assigned_group.id, project_group_2.id].map(&:to_s)

        post delete_multiple_project_groups_path, params: { selections: { group: selected_ids } }

        expect(response).to have_http_status(:not_found)
        expect(GrdaWarehouse::ProjectGroup.find_by(id: assigned_group.id)).to be_present
        expect(GrdaWarehouse::ProjectGroup.find_by(id: project_group_2.id)).to be_present
        expect(Collection.find_by(id: assigned_collection.id)).to be_present
        expect(Collection.find_by(id: unassigned_collection.id)).to be_present
      end

      it 'can open the assigned group' do
        get edit_project_group_path(assigned_group)
        expect(response).to have_http_status(:ok)
      end

      context 'when submitting selections the editor cannot see' do
        let(:submitted_filters) do
          {
            notes: '',
            project_ids: [visible_project.id, confidential_project.id, hidden_project.id].map(&:to_s),
            organization_ids: [hidden_organization.id].map(&:to_s),
            data_source_ids: [other_data_source.id].map(&:to_s),
            excluded_project_ids: [excluded_hidden_project.id].map(&:to_s),
            project_group_ids: [project_group_2.id].map(&:to_s),
            users: [''],
            editor_ids: [restricted_user.id.to_s],
          }
        end

        def expect_only_viewable_selections(group, excluded_project_ids: [])
          filter = group.filter
          expect(filter.project_ids).to contain_exactly(visible_project.id)
          expect(filter.organization_ids).to be_empty
          expect(filter.data_source_ids).to be_empty
          expect(filter.excluded_project_ids).to match_array(excluded_project_ids)
          expect(filter.project_group_ids).to be_empty
          expect(group.projects).to contain_exactly(visible_project)
        end

        it 'drops them on update, keeping the saved exclusion of a project the editor cannot see' do
          patch project_group_path(assigned_group), params: { filters: submitted_filters.merge(name: 'Assigned Group') }

          expect(response).to redirect_to(edit_project_group_path(assigned_group))
          expect_only_viewable_selections(assigned_group.reload, excluded_project_ids: [excluded_hidden_project.id])
        end

        it 'keeps the saved exclusion of a project the editor cannot see when the form omits it' do
          patch project_group_path(assigned_group), params: { filters: submitted_filters.merge(name: 'Assigned Group', excluded_project_ids: ['']) }

          expect(assigned_group.reload.filter.excluded_project_ids).to contain_exactly(excluded_hidden_project.id)
        end

        it 'drops them on create' do
          expect do
            post project_groups_path, params: { filters: submitted_filters.merge(name: 'New Restricted Group') }
          end.to change(GrdaWarehouse::ProjectGroup, :count).by(1)

          expect_only_viewable_selections(GrdaWarehouse::ProjectGroup.find_by!(name: 'New Restricted Group'))
        end
      end
    end

    context 'with legacy permissions' do
      let!(:restricted_user) { create(:user) }
      let!(:restricted_role) { create(:role, can_edit_assigned_project_groups: true, can_view_projects: true) }

      before do
        restricted_user.legacy_roles << restricted_role
        access_group = create(:access_group)
        access_group.add(restricted_user)
        access_group.add_viewable(visible_project)
        access_group.add_viewable(visible_organization)
        access_group.add_viewable(assigned_group)
        restricted_user.clear_memery_cache!
        sign_in restricted_user
      end

      it_behaves_like 'a restricted editor'
    end

    context 'with ACL permissions' do
      let!(:restricted_user) { create(:acl_user) }
      let!(:restricted_role) { create(:role, can_edit_assigned_project_groups: true, can_view_projects: true) }

      before do
        collection = create(:collection)
        collection.set_viewables(
          projects: [visible_project.id],
          organizations: [visible_organization.id],
          project_groups: [assigned_group.id],
        )
        setup_access_control(restricted_user, restricted_role, collection)
        sign_in restricted_user
      end

      it_behaves_like 'a restricted editor'
    end
  end

  describe 'legacy user with can_edit_project_groups' do
    it 'can edit any group' do
      get edit_project_group_path(project_group_2)
      expect(response).to have_http_status(:ok)
    end
  end

  # Regression coverage: this form is a project-management CRUD context (gated
  # by can_edit_some_project_groups), not a report-queuing context, so its
  # Organizations/Data Sources dropdowns must be scoped by can_view_projects,
  # not the can_view_assigned_reports default used by report filter forms.
  describe 'GET #new for an ACL user with can_view_projects but not can_view_assigned_reports' do
    let!(:acl_user) { create(:acl_user) }
    let!(:project_groups_role) { create(:role, can_edit_project_groups: true, can_view_projects: true) }
    let!(:collection) { create(:collection) }

    before do
      collection.set_viewables(data_sources: [data_source.id])
      setup_access_control(acl_user, project_groups_role, collection)
      sign_in(acl_user)
    end

    it 'populates the Organizations and Data Sources dropdowns' do
      get new_project_group_path
      expect(response).to have_http_status(:ok)
      doc = Nokogiri::HTML(response.body)
      expect(doc.at_css('select[name="filters[organization_ids][]"]').css('option')).not_to be_empty
      expect(doc.at_css('select[name="filters[data_source_ids][]"]').css('option')).not_to be_empty
    end

    it 'scopes the Projects pickers by can_view_projects' do
      get new_project_group_path
      doc = Nokogiri::HTML(response.body)
      paths = ['project_ids', 'excluded_project_ids'].map do |field|
        doc.at_css("select[name=\"filters[#{field}][]\"]")['data-collection-path']
      end
      expect(paths).to all(include('permission=can_view_projects'))
    end
  end
end
