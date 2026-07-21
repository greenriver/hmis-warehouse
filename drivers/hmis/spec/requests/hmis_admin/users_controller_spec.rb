###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'

RSpec.describe HmisAdmin::UsersController, type: :request, if: AuthMethod.jwt? do
  include_context 'with a creation-capable IdP connector'

  let!(:data_source) { create(:hmis_data_source) }
  let!(:admin_user) { create(:acl_user, first_name: 'Admin', last_name: 'User') }

  before(:each) do
    # Grant HMIS admin access to the same user record signed in on the warehouse side.
    create_access_control(Hmis::User.find(admin_user.id), [])
    sign_in admin_user
  end

  it_behaves_like 'admin IdP-backed user creation' do
    let(:user_class) { Hmis::User }
    let(:users_index_path) { hmis_admin_users_path }
    let(:create_form_path) { new_hmis_admin_user_path }
    let(:next_step_pattern) { /user groups/i }

    def edit_path_for(user)
      edit_hmis_admin_user_path(user)
    end
  end

  describe 'GET edit' do
    let!(:target) { create(:acl_user, first_name: 'Target', last_name: 'User') }

    it 'renders the edit form for the target user' do
      get edit_hmis_admin_user_path(target)

      expect(response).to have_http_status(:ok)
      expect(assigns(:user).id).to eq(target.id)
    end
  end

  describe 'PATCH update' do
    let!(:target) { create(:acl_user, first_name: 'Target', last_name: 'User') }

    context 'assigning user groups directly' do
      let!(:group) { create(:hmis_user_group) }

      it 'sets the group membership from user_group_ids' do
        patch hmis_admin_user_path(target), params: { user: { user_group_ids: [group.id] } }

        expect(Hmis::User.find(target.id).user_groups).to contain_exactly(group)
        expect(response).to redirect_to(edit_hmis_admin_user_path(target))
      end
    end

    context 'copying groups from another user' do
      let!(:source_user) { create(:acl_user, first_name: 'Source', last_name: 'User') }
      let!(:source_group) { create(:hmis_user_group) }
      let!(:existing_group) { create(:hmis_user_group) }

      before do
        source_group.add(source_user)
        existing_group.add(target)
      end

      it "adds the source user's groups without removing the target's existing groups" do
        patch hmis_admin_user_path(target), params: { user: { copy_form_id: source_user.id.to_s } }

        expect(Hmis::User.find(target.id).user_groups).to contain_exactly(existing_group, source_group)
      end
    end

    context 'when copy_form_id is blank' do
      let!(:existing_group) { create(:hmis_user_group) }

      before { existing_group.add(target) }

      it 'leaves existing group membership untouched' do
        patch hmis_admin_user_path(target), params: { user: { copy_form_id: '' } }

        expect(Hmis::User.find(target.id).user_groups).to contain_exactly(existing_group)
      end
    end
  end

  describe 'when signed in as a non-admin' do
    let!(:non_admin) { create(:acl_user, first_name: 'View', last_name: 'Only') }
    let!(:target) { create(:acl_user, first_name: 'Target', last_name: 'User') }

    before do
      create_access_control(Hmis::User.find(non_admin.id), [], without_permission: :can_administer_hmis)
      sign_in non_admin
    end

    it 'refuses GET index' do
      get hmis_admin_users_path

      expect(response).to have_http_status(:redirect)
    end

    it 'refuses GET new' do
      get new_hmis_admin_user_path

      expect(response).to have_http_status(:redirect)
    end

    it 'refuses POST create and provisions nothing' do
      expect do
        post hmis_admin_users_path, params: { user: { first_name: 'New', last_name: 'Bie', email: 'newbie@example.com', connector_id: connector_id } }
      end.not_to change(Hmis::User, :count)

      expect(response).to have_http_status(:redirect)
      expect(a_request(:post, users_url)).not_to have_been_made
    end

    it 'refuses GET edit' do
      get edit_hmis_admin_user_path(target)

      expect(response).to have_http_status(:redirect)
    end

    it 'refuses PATCH update and leaves group membership unchanged' do
      group = create(:hmis_user_group)

      patch hmis_admin_user_path(target), params: { user: { user_group_ids: [group.id] } }

      expect(Hmis::User.find(target.id).user_groups).to be_empty
      expect(response).to have_http_status(:redirect)
    end
  end
end
