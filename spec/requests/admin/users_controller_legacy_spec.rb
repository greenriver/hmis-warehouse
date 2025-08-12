# frozen_string_literal: true

require 'rails_helper'
require_relative './admin_users_search_spec_context'

RSpec.describe Admin::UsersController, type: :request do
  let(:other_admin) { create(:user) }
  let!(:user) { create(:user, first_name: 'Regular', last_name: 'User') }
  let!(:admin_user) { create(:user) }
  let!(:admin_role) { create :admin_role }

  before(:each) do
    admin_user.legacy_roles << admin_role
    other_admin.legacy_roles << admin_role
  end

  # Required for the 'admin users search' shared context
  let!(:user_to_find) { create(:user, first_name: 'Alice', last_name: 'Smith') }

  include_context 'admin users search'

  describe 'GET edit' do
    before(:each) do
      sign_in admin_user
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
        sign_in admin_user
        patch admin_user_path(updated_user), params: { user: { notify_on_vispdat_completed: '1' } }
      end
      it 'flips to true' do
        expect(updated_user.reload.notify_on_vispdat_completed).to be true
      end
    end

    context 'when updating new client notifications' do
      let(:updated_user) { User.not_system.first }

      before(:each) do
        sign_in admin_user
        patch admin_user_path(updated_user), params: { user: { notify_on_client_added: '1' } }
      end

      it 'flips to true' do
        expect(updated_user.reload.notify_on_client_added).to be true
      end
    end
  end
end
