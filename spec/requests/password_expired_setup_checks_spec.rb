###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Password expired with pending account setup', :devise_only, type: :request do
  let!(:user) { create(:acl_user) }
  let!(:role) { create(:admin_role) }
  let!(:collection) { create(:collection) }
  let!(:requirement) { create(:compliance_requirement, content_page: create(:content_page), active: true) }
  let(:new_password) { Digest::SHA256.hexdigest('new-secret-password') }

  before { setup_access_control(user, role, collection) }

  context 'when the password is expired' do
    before do
      user.need_change_password!
      sign_in user
    end

    it 'renders the password change page instead of redirecting to the compliance agreement' do
      get user_password_expired_path
      expect(response).to have_http_status(:ok)
      expect(response).to render_template('devise/password_expired/show')
    end

    it 'accepts the new password, then still requires the compliance agreement' do
      put user_password_expired_path, params: {
        user: { current_password: user.password, password: new_password, password_confirmation: new_password },
      }
      expect(response).to redirect_to(root_path)
      expect(user.reload.password_changed_at).not_to be_nil
      expect(user.valid_password?(new_password)).to be(true)

      get root_path
      expect(response).to redirect_to(compliance_agreement_path)
    end
  end

  context 'when the password is not expired' do
    before { sign_in user }

    it 'sends the user from the password page on to the compliance agreement' do
      get user_password_expired_path
      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response).to redirect_to(compliance_agreement_path)
    end
  end
end
