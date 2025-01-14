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

    context 'when updating user to ACLs' do
      let!(:legacy_user) { create :user }
      let!(:user_group)  { create :user_group }

      it 'updated user keeps assigned user groups' do
        user_group.add(legacy_user)
        # Ensure the orignal user is using role-based permissions and is assigned the user group
        expect(legacy_user.permission_context).to eq('role_based')
        expect(legacy_user.user_group_ids).to eq([user_group.id])
        patch admin_user_path(legacy_user), params: { user: { permission_context: 'acls' } }
        # Ensure the updated user is using ACLs and is still assigned the user group
        expect(legacy_user.reload.permission_context).to eq('acls')
        expect(legacy_user.reload.user_group_ids).to eq([user_group.id])
      end
    end
  end
end
