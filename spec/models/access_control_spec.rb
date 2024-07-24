require 'rails_helper'

RSpec.describe AccessControl, type: :model do
  let!(:data_source) { create :data_source_fixed_id }
  let!(:organization) { create :grda_warehouse_hud_organization }
  let!(:hidden_project) { create :grda_warehouse_hud_project, organization: organization, project_name: 'Hidden Project' }
  let!(:viewable_project) { create :grda_warehouse_hud_project, organization: organization, project_name: 'Viewable Project' }
  let!(:editable_project) { create :grda_warehouse_hud_project, organization: organization, project_name: 'Editable Project' }
  let!(:view_project_role) { create :role, can_view_projects: true, name: 'view project' }
  let!(:edit_project_role) { create :role, can_edit_projects: true, name: 'edit project' }
  let!(:can_view_clients_role) { create :role, can_view_clients: true, name: 'view client' } # used to test cross access_control collection access
  let!(:view_user) { create :acl_user, first_name: 'View', last_name: 'User' }
  let!(:edit_user) { create :acl_user, first_name: 'Edit', last_name: 'User' }
  let!(:no_access_user) { create :acl_user, first_name: 'No Access', last_name: 'User' }
  let!(:view_one_edit_one_user) { create :acl_user, first_name: 'View and Edit', last_name: 'User' }
  let!(:view_project_user_group) { create :user_group }
  let!(:edit_project_user_group) { create :user_group }
  let!(:view_project_collection) { create :collection }
  let!(:edit_project_collection) { create :collection }
  let!(:hidden_project_collection) { create :collection }
  let!(:no_access_user_group) { create :user_group }
  let!(:view_project_access_control) { create :access_control, role: view_project_role, collection: view_project_collection, user_group: view_project_user_group }
  let!(:edit_project_access_control) { create :access_control, role: edit_project_role, collection: edit_project_collection, user_group: edit_project_user_group }
  let!(:client_view_access_control) { create :access_control, role: can_view_clients_role, collection: view_project_collection, user_group: no_access_user_group }
  let!(:unused_access_control) { create :access_control, role: can_view_clients_role, collection: hidden_project_collection, user_group: view_project_user_group }

  describe 'Checking access' do
    before do
      view_project_collection.set_viewables({ projects: [viewable_project.id] })
      edit_project_collection.set_viewables({ projects: [editable_project.id] })
      hidden_project_collection.set_viewables({ projects: [hidden_project.id] })
      view_project_user_group.add(view_user)
      view_project_user_group.add(view_one_edit_one_user)
      edit_project_user_group.add(edit_user)
      edit_project_user_group.add(view_one_edit_one_user)
      no_access_user_group.add(no_access_user)
    end
    describe 'Viewing a project' do
      it 'view user can view the viewable project' do
        expect(GrdaWarehouse::Hud::Project.viewable_by(view_user, permission: :can_view_projects)).to include viewable_project
      end
      it 'view and edit user can view the viewable project' do
        expect(GrdaWarehouse::Hud::Project.viewable_by(view_one_edit_one_user, permission: :can_view_projects)).to include viewable_project
      end
      it 'view and edit user cannot view the editable project' do
        expect(GrdaWarehouse::Hud::Project.viewable_by(view_one_edit_one_user, permission: :can_view_projects)).to_not include editable_project
      end
      it 'edit user cannot view the viewable project (only granted edit access)' do
        expect(GrdaWarehouse::Hud::Project.viewable_by(edit_user, permission: :can_view_projects)).to_not include editable_project
      end
      it 'user with no access cannot view the viewable project' do
        expect(GrdaWarehouse::Hud::Project.viewable_by(no_access_user, permission: :can_view_projects)).not_to include viewable_project
      end
    end
    describe 'Editing a project' do
      it 'view user cannot edit the editable project' do
        expect(GrdaWarehouse::Hud::Project.editable_by(view_user)).to_not include editable_project
      end
      it 'view and edit user cannot edit the viewable project' do
        expect(GrdaWarehouse::Hud::Project.editable_by(view_one_edit_one_user)).to_not include viewable_project
      end
      it 'view and edit user can edit the editable project' do
        expect(GrdaWarehouse::Hud::Project.editable_by(view_one_edit_one_user)).to include editable_project
      end
      it 'edit user can edit the editable project' do
        expect(GrdaWarehouse::Hud::Project.editable_by(edit_user)).to include editable_project
      end
      it 'user with no access cannot edit the editable project' do
        expect(GrdaWarehouse::Hud::Project.editable_by(no_access_user)).not_to include editable_project
      end
    end

    describe 'collections_for_permission returns correct collection ids' do
      it 'only view client collection is returned' do
        expect(view_one_edit_one_user.collections_for_permission(:can_view_clients)).to eq([hidden_project_collection.id])
      end
      it 'only view project collection is returned' do
        expect(view_one_edit_one_user.collections_for_permission(:can_view_projects)).to eq([view_project_collection.id])
      end
      it 'only edit project collection is returned' do
        expect(view_one_edit_one_user.collections_for_permission(:can_edit_projects)).to eq([edit_project_collection.id])
      end
    end
  end
end
