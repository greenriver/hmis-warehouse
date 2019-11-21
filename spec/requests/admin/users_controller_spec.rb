require 'rails_helper'

RSpec.describe Admin::UsersController, type: :request do
  let!(:user) { create(:user) }
  let!(:admin)       { create(:user) }
  let!(:admin_role)  { create :admin_role }

  before(:each) do
    sign_in admin
    admin.roles << admin_role
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
  end
end
