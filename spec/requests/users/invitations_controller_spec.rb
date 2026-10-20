###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Users::InvitationsController', :devise_only, type: :request do
  let(:admin_user) { create(:acl_user) }
  let(:admin_role) { create :admin_role }
  let(:no_data_source_collection) { create :collection }
  let(:agency) { create(:agency) }

  let(:invite_params) do
    {
      user: {
        first_name: 'John',
        last_name: 'Doe',
        email: 'john.doe@example.com',
        agency_id: agency.id,
      },
    }
  end

  describe 'inviting a user' do
    context 'when not signed in' do
      it 'redirects GET /users/invitation/new' do
        get new_user_invitation_path

        expect(response).to redirect_to(root_path)
      end

      it 'does not invite through POST /users/invitation' do
        expect do
          post user_invitation_path, params: invite_params
        end.not_to change(User, :count)

        expect(response).to redirect_to(root_path)
      end

      it 'does not invite through POST /users/invitations/confirm' do
        expect do
          post confirm_users_invitations_path, params: invite_params
        end.not_to change(User, :count)

        expect(response).to redirect_to(root_path)
      end
    end

    context 'when signed in without can_edit_users' do
      let(:user) { create(:acl_user) }

      before { sign_in user }

      it 'redirects GET /users/invitation/new' do
        get new_user_invitation_path

        expect(response).to redirect_to(user.my_root_path)
      end

      it 'does not invite through POST /users/invitation' do
        expect do
          post user_invitation_path, params: invite_params
        end.not_to change(User, :count)

        expect(response).to redirect_to(user.my_root_path)
      end

      it 'does not invite through POST /users/invitations/confirm' do
        expect do
          post confirm_users_invitations_path, params: invite_params
        end.not_to change(User, :count)

        expect(response).to redirect_to(user.my_root_path)
      end
    end

    context 'when signed in with can_edit_users' do
      before do
        sign_in admin_user
        setup_access_control(admin_user, admin_role, no_data_source_collection)
      end

      it 'renders GET /users/invitation/new' do
        get new_user_invitation_path

        expect(response).to have_http_status(:ok)
      end

      it 'invites through POST /users/invitation' do
        expect do
          post user_invitation_path, params: invite_params
        end.to change(User, :count).by(1)

        invited_user = User.find_by!(email: 'john.doe@example.com')
        expect(response).to redirect_to(edit_admin_user_path(invited_user))
      end

      it 'invites through POST /users/invitations/confirm' do
        expect do
          post confirm_users_invitations_path, params: invite_params
        end.to change(User, :count).by(1)

        invited_user = User.find_by!(email: 'john.doe@example.com')
        expect(response).to redirect_to(edit_admin_user_path(invited_user))
      end
    end
  end

  describe 'accepting or removing an invitation' do
    let!(:invited_user) do
      invitee_attributes = {
        first_name: 'Jane',
        last_name: 'Invitee',
        email: 'jane.invitee@example.com',
        agency_id: agency.id,
      }
      User.invite!(invitee_attributes) { |user| user.skip_invitation = true }
    end
    let(:invitation_token) { invited_user.raw_invitation_token }
    let(:new_password) { 'correct-horse-battery-staple-42' }
    let(:accept_params) do
      {
        user: {
          invitation_token: invitation_token,
          password: new_password,
          password_confirmation: new_password,
        },
      }
    end

    context 'when not signed in' do
      it 'renders GET /users/invitation/accept with a valid token' do
        get accept_user_invitation_path(invitation_token: invitation_token)

        expect(response).to have_http_status(:ok)
      end

      it 'redirects GET /users/invitation/accept with an invalid token' do
        get accept_user_invitation_path(invitation_token: 'not-a-token')

        expect(response).to have_http_status(:redirect)
      end

      it 'accepts through PUT /users/invitation with a valid token' do
        put user_invitation_path, params: accept_params

        expect(invited_user.reload.invitation_accepted_at).to be_present
      end

      it 'does not accept through PUT /users/invitation with an invalid token' do
        accept_params[:user][:invitation_token] = 'not-a-token'

        put user_invitation_path, params: accept_params

        expect(invited_user.reload.invitation_accepted_at).to be_nil
      end

      it 'removes through GET /users/invitation/remove with a valid token' do
        get remove_user_invitation_path(invitation_token: invitation_token)

        expect(User.exists?(invited_user.id)).to be(false)
      end

      it 'does not remove through GET /users/invitation/remove with an invalid token' do
        get remove_user_invitation_path(invitation_token: 'not-a-token')

        expect(User.exists?(invited_user.id)).to be(true)
      end
    end

    # require_no_authentication turns away a signed-in user, so one account can't act on another's
    # invitation
    context 'when signed in' do
      let(:user) { create(:acl_user) }

      before { sign_in user }

      it 'redirects GET /users/invitation/accept' do
        get accept_user_invitation_path(invitation_token: invitation_token)

        expect(response).to have_http_status(:redirect)
      end

      it 'does not accept through PUT /users/invitation' do
        put user_invitation_path, params: accept_params

        expect(invited_user.reload.invitation_accepted_at).to be_nil
      end

      it 'does not remove through GET /users/invitation/remove' do
        get remove_user_invitation_path(invitation_token: invitation_token)

        expect(User.exists?(invited_user.id)).to be(true)
      end
    end
  end
end
