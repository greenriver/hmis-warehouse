require 'rails_helper'

RSpec.describe Admin::UsersController, type: :request do
  let!(:user) { create(:acl_user) }
  let!(:admin)       { create(:acl_user) }
  let!(:admin_role)  { create :admin_role }
  let!(:no_data_source_collection) { create :collection }

  before(:each) do
    sign_in admin
    setup_access_control(admin, admin_role, no_data_source_collection)
  end

  describe 'GET edit' do
    before(:each) do
      get edit_admin_user_path(user)
    end

    it 'assigns user' do
      expect(assigns(:user)).to eq user
    end

    it 'renders edit' do
      expect(response).to render_template :edit
    end
  end

  describe 'DELETE disable' do
    context 'when the user is valid' do
      it 'disables the user' do
        expect do
          delete admin_user_path(user)
        end.to change { User.active.count }.by(-1)

        user.reload
        expect(user.active).to eq(false)
      end
    end

    context 'when the user is invalid' do
      before do
        user.update_column(:email, 'invalid-email') # skip validations
      end

      it 'still disables the user' do
        delete admin_user_path(user)

        user.reload
        expect(user.active).to eq(false)
      end
    end
  end

  describe 'PUT update' do
    context 'when updating vi-spdat notifications' do
      let(:updated_user) { User.not_system.first }
      before(:each) do
        patch admin_user_path(updated_user), params: { user: { notify_on_vispdat_completed: '1' } }
      end
      it 'flips to true' do
        expect(updated_user.reload.notify_on_vispdat_completed).to be true
      end
    end

    context 'when updating new client notifications' do
      let(:updated_user) { User.not_system.first }

      before(:each) do
        patch admin_user_path(updated_user), params: { user: { notify_on_client_added: '1' } }
      end

      it 'flips to true' do
        expect(updated_user.reload.notify_on_client_added).to be true
      end
    end

    context 'when updating user from Role-Based to ACLs' do
      let!(:legacy_user)  { create :user }
      let!(:user_group)   { create :user_group }
      let!(:role)         { create :role }
      let!(:access_group) { create :access_group }

      it 'updated user keeps fields' do
        user_group.add(legacy_user)
        legacy_user.legacy_roles << role
        legacy_user.access_groups << access_group
        legacy_user.save!
        # Ensure the orignal user is using role-based permissions and is assigned the user group
        expect(legacy_user.permission_context).to eq('role_based')
        expect(legacy_user.user_group_ids).to eq([user_group.id])
        expect(legacy_user.legacy_role_ids).to eq([role.id])
        expect(legacy_user.access_group_ids.include?(access_group.id)).to be true
        # The Role-Based user edit form does not include a field for user_group_ids. As a result, it will
        # not be included in the parameters sent when switching from Role-Based permissions to ACLs
        patch admin_user_path(legacy_user), params: { user: { permission_context: 'acls', access_group_ids: [access_group.id] } }
        # Ensure the updated user is using ACLs and is still assigned the user group
        expect(legacy_user.reload.permission_context).to eq('acls')
        expect(legacy_user.reload.user_group_ids).to eq([user_group.id])
        expect(legacy_user.reload.legacy_role_ids).to eq([role.id])
        expect(legacy_user.reload.access_group_ids.include?(access_group.id)).to be true
      end
    end

    context 'when updating user from ACLs to Role-Based' do
      let!(:acl_user)   { create(:acl_user) }
      let!(:user_group) { create :user_group }
      let!(:role)       { create :role }
      let!(:access_group) { create :access_group }

      it 'updated user keeps fields' do
        user_group.add(acl_user)
        acl_user.legacy_roles << role
        acl_user.access_groups << access_group
        acl_user.save!
        # Ensure the orignal user is using role-based permissions and is assigned the user group
        expect(acl_user.permission_context).to eq('acls')
        expect(acl_user.user_group_ids).to eq([user_group.id])
        expect(acl_user.legacy_role_ids).to eq([role.id])
        expect(acl_user.access_group_ids.include?(access_group.id)).to be true
        # The ACL user edit form includes a field for user_group_ids. As a result, it will be
        # included in the parameters sent when switching from ACLs to Role-Based permissions
        patch admin_user_path(acl_user), params: { user: { permission_context: 'role_based', user_group_ids: [user_group.id] } }
        # Ensure the updated user is using ACLs and is still assigned the user group
        expect(acl_user.reload.permission_context).to eq('role_based')
        expect(acl_user.reload.user_group_ids).to eq([user_group.id])
        expect(acl_user.reload.legacy_role_ids).to eq([role.id])
        expect(acl_user.reload.access_group_ids.include?(access_group.id)).to be true
      end
    end
  end
end
