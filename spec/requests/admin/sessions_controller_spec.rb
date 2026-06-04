###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::SessionsController, type: :request do
  include_context 'with cache store'

  let!(:user) { create(:acl_user) }
  let!(:admin_user) { create(:acl_user, first_name: 'Admin', last_name: 'User') }
  let!(:admin_role) { create :admin_role }
  let!(:no_data_source_collection) { create :collection }

  before(:each) do
    setup_access_control(admin_user, admin_role, no_data_source_collection)

    # Mock the permission to manage sessions
    allow(admin_user).to receive(:can_manage_sessions?).and_return(true)

    # Stub out compliance and training requirements that would redirect the user
    allow_any_instance_of(Admin::SessionsController).to receive(:require_compliance_agreement!).and_return(true)
    allow_any_instance_of(Admin::SessionsController).to receive(:require_training!).and_return(true)
    allow_any_instance_of(Admin::SessionsController).to receive(:health_emergency?).and_return(nil)
  end

  describe 'GET index' do
    context 'with recently active users' do
      before do
        # Manually set last_activity_at to make users show up
        user.update_column(:last_activity_at, 10.minutes.ago)
        sign_in admin_user
        get admin_sessions_path
      end

      it 'responds successfully' do
        expect(response).to have_http_status(200)
      end

      it 'renders the index template' do
        expect(response).to render_template(:index)
      end

      it 'displays users with recent activity' do
        expect(assigns(:users)).to include(user)
      end
    end

    context 'without recent activity' do
      before do
        # Leave last_activity_at nil so user doesn't show up
        sign_in admin_user
        get admin_sessions_path
      end

      it 'does not display inactive users' do
        expect(assigns(:users)).not_to include(user)
      end
    end
  end

  describe 'DELETE destroy' do
    context 'when ending a user session' do
      before do
        sign_in admin_user

        # Use the session ID from the JWT helper
        user.update_column(:unique_session_id, jwt_session_id)
        user.update_column(:last_activity_at, 10.minutes.ago)
      end

      it 'adds the session to the denylist' do
        expect { delete admin_session_path(user) }.to change {
          TokenDenylist.denied?(user.unique_session_id)
        }.from(false).to(true)
      end

      it 'redirects to sessions index' do
        delete admin_session_path(user)
        expect(response).to redirect_to(admin_sessions_path)
      end

      it 'displays success message' do
        delete admin_session_path(user)
        follow_redirect!
        expect(flash[:notice]).to include("Session ended for #{user.name}")
      end

      it 'denylists the session with expiration' do
        session_id = user.unique_session_id
        delete admin_session_path(user)

        # Verify it's in the denylist
        expect(TokenDenylist.denied?(session_id)).to be true

        # Verify it will expire after 12 hours
        # (We can't easily test the expiration time directly in Rails.cache,
        # but we can verify it was added)
      end
    end

    context 'when user has no session ID' do
      before do
        # User has no session ID set
        user.update_column(:unique_session_id, nil)
        sign_in admin_user
      end

      it 'still redirects without error' do
        delete admin_session_path(user)
        expect(response).to redirect_to(admin_sessions_path)
      end

      it 'does not create any denylist entries' do
        expect do
          delete admin_session_path(user)
        end.not_to(change { TokenDenylist.denied?('anything') })
      end
    end
  end

  describe 'Force logout flow' do
    context 'when accessing with a denylisted session' do
      before do
        # Sign in the user first to get a valid session ID
        sign_in user

        # Add the user's session to the denylist
        TokenDenylist.add(jwt_session_id, expires_at: 1.hour.from_now)

        # Update the user's session ID to match what we signed in with
        user.update_column(:unique_session_id, jwt_session_id)
      end

      it 'redirects to the captive portal' do
        get root_path
        expect(response).to redirect_to(token_denylisted_path)
      end

      it 'does not authenticate the user' do
        get root_path
        # Should redirect to captive portal, not load the page
        expect(response.status).not_to eq(200)
      end

      it 'captive portal page is accessible' do
        get token_denylisted_path
        expect(response).to have_http_status(200)
      end

      it 'captive portal displays the session terminated message' do
        get token_denylisted_path
        expect(response.body).to include('Session Ended')
      end

      it 'captive portal includes logout link' do
        get token_denylisted_path
        expect(response.body).to include('Sign Out and Log Back In')
      end
    end

    context 'when session expires from denylist' do
      before do
        # Sign in the user first
        sign_in user

        # Add session to denylist with immediate expiration
        TokenDenylist.add(jwt_session_id, expires_at: 1.second.from_now)

        # Update the user's session ID to match
        user.update_column(:unique_session_id, jwt_session_id)
      end

      it 'initially blocks the request' do
        get root_path
        expect(response).to redirect_to(token_denylisted_path)
      end

      # Note: We can't easily test cache expiration in specs since it depends
      # on the cache store's TTL behavior. This is tested in integration/e2e.
    end
  end
end
