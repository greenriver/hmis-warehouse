###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AccessControlsController, type: :request do
  include AccessControlSetup

  let(:user) { create(:acl_user) }
  let(:collection) { create(:collection) }

  # A second, unrelated access control -- the record the request is trying to read.
  let!(:audited_access_control) do
    setup_access_control(create(:acl_user), create(:role, can_view_clients: true), create(:collection))
  end

  def sign_in_with(role)
    setup_access_control(user, role, collection)
    sign_in(user)
  end

  describe 'GET /access_controls/:id' do
    it 'denies a signed-in user who cannot edit users' do
      sign_in_with(create(:role, can_view_clients: true))

      get access_control_path(audited_access_control)

      aggregate_failures do
        expect(response).to have_http_status(:redirect)
        expect(flash[:alert]).to be_present
      end
    end

    it 'denies a user whose only elevated permission is an adjacent admin one' do
      # can_audit_users is deliberately close to, but not, the gate: holding some
      # user-administration permission must not be enough on its own.
      sign_in_with(create(:role, can_audit_users: true))

      get access_control_path(audited_access_control)

      expect(response).to have_http_status(:redirect)
    end

    it 'allows a user who can edit users, and renders the record' do
      sign_in_with(create(:role, can_edit_users: true))

      get access_control_path(audited_access_control)

      aggregate_failures do
        expect(response).to have_http_status(:success)
        expect(assigns(:access_control)).to eq(audited_access_control)
        expect(response.body).to include(audited_access_control.role.name)
      end
    end
  end
end
