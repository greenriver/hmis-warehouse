###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# Regression guard for the Login Locations tab in admin/audits/_user_tabs: it's gated on
# @user.login_locations_enabled? (true for Devise, false for JWT — see Idp::Support and
# OmniauthSupport), so it renders for the Devise arm and is omitted for the JWT arm, where the
# admin_user_locations_path route helper isn't defined at all and would raise NoMethodError.
# Runs under whichever AUTH_METHOD the suite is booted with; see the JWT CI step for the
# AUTH_METHOD=jwt boot of this same file.
RSpec.describe 'Admin::Audits', type: :request do
  let(:admin_user) { create(:user) }
  let(:target_user) { create(:user, first_name: 'Test', last_name: 'User') }

  before do
    allow_any_instance_of(User).to receive(:can_audit_users?).and_return(true)
    sign_in admin_user
  end

  it 'renders the audit page and shows Login Locations only under the Devise arm' do
    get admin_user_audit_path(target_user)

    expect(response).to have_http_status(:success)
    if AuthMethod.jwt?
      expect(response.body).not_to include('Login Locations')
    else
      expect(response.body).to include('Login Locations')
    end
  end
end
