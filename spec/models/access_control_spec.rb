require 'rails_helper'

RSpec.describe AccessControl, type: :model do
  let!(:data_source) { create :data_source_fixed_id }
  let!(:organization) { create :grda_warehouse_hud_organization }
  let!(:hidden_project) { create :grda_warehouse_hud_project, organization: organization }
  let!(:viewable_project) { create :grda_warehouse_hud_project, organization: organization }
  let!(:editable_project) { create :grda_warehouse_hud_project, organization: organization }
  let!(:view_project_role) { create :role, can_view_projects: true }
  let!(:edit_project_role) { create :role, can_edit_projects: true }
  let!(:view_user) { create :user, first_name: 'View', last_name: 'User' }
  let!(:edit_user) { create :user, first_name: 'Edit', last_name: 'User' }
  let!(:no_access_user) { create :user, first_name: 'No Access', last_name: 'User' }
  let!(:view_one_edit_one_user) { create :user, first_name: 'View and Edit', last_name: 'User' }
  let!(:view_project_user_group) { create :user_group }
  let!(:edit_project_user_group) { create :user_group }
  let!(:view_project_entity_group) { create :access_group }
  let!(:edit_project_entity_group) { create :access_group }
  let!(:view_project_access_control) { create :access_control, role: view_project_role, access_group: view_project_entity_group, user_group: view_project_user_group }
  let!(:edit_project_access_control) { create :access_control, role: edit_project_role, access_group: edit_project_entity_group, user_group: edit_project_user_group }

  describe 'Checking access' do
    before do
      view_project_entity_group.set_viewables({ projects: [viewable_project.id] })
      edit_project_entity_group.set_viewables({ projects: [editable_project.id] })
      view_project_user_group.add(view_user)
      view_project_user_group.add(view_one_edit_one_user)
      edit_project_user_group.add(edit_user)
      edit_project_user_group.add(view_one_edit_one_user)
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
  end
end
