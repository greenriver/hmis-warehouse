###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# Regression guard for the Login Locations tab in admin/audits/_user_tabs: it's gated on
# @user.login_locations_enabled? (true for Devise, false for JWT — see Idp::Support and
# DeviseOktaSupport), so it renders for the Devise arm and is omitted for the JWT arm, where the
# admin_user_locations_path route helper isn't defined at all and would raise NoMethodError.
# Runs under whichever AUTH_METHOD the suite is booted with; see the JWT CI step for the
# AUTH_METHOD=jwt boot of this same file. That CI step names this file explicitly in its rspec
# invocation — if it's ever dropped from that list, the JWT-arm half of this guard silently stops
# running (a Devise-arm run can't catch it: admin_user_locations_path exists either way there).
RSpec.describe 'Admin::Audits', type: :request do
  let(:admin_user) { create(:acl_user) }
  let(:target_user) { create(:user, first_name: 'Test', last_name: 'User') }
  let(:audit_role) { create(:role, can_audit_users: true) }
  let(:collection) { create(:collection) }

  # can_audit_users? is computed per-instance from the user's roles (User#load_effective_permissions),
  # so it has to be granted for real: under JWT, current_user is re-fetched from the DB on every
  # request (Idp::UserProvisioner), which loses a stub set on the `admin_user` object itself.
  before do
    setup_access_control(admin_user, audit_role, collection)
    sign_in admin_user
  end

  it 'renders the audit page and shows Login Locations only under the Devise arm' do
    get admin_user_audit_path(target_user)

    expect(response).to have_http_status(:success)
    if AuthMethod.jwt?
      expect(response.body).not_to include('Login Locations')
      expect { admin_user_locations_path(target_user) }.to raise_error(NoMethodError)
    else
      expect(response.body).to include('Login Locations')
    end
  end

  it 'only lists activity for the requested user' do
    ActivityLog.create!(user: target_user, controller_name: 'target-only-marker', action_name: 'show', ip_address: '127.0.0.1')
    ActivityLog.create!(user: admin_user, controller_name: 'other-user-marker', action_name: 'show', ip_address: '127.0.0.1')

    get admin_user_audit_path(target_user)

    expect(response.body).to include('target-only-marker')
    expect(response.body).not_to include('other-user-marker')
  end

  context 'when the signed-in user lacks can_audit_users?' do
    let(:non_admin) { create(:user) }

    before { sign_in non_admin }

    it 'redirects instead of exposing the audit trail' do
      get admin_user_audit_path(target_user)

      expect(response).to have_http_status(:redirect)
      expect(flash[:alert]).to eq('Sorry you are not authorized to do that.')
    end
  end
end
