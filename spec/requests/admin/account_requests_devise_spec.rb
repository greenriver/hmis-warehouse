###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::AccountRequestsController, :devise_only, type: :request do
  let!(:admin) { create(:user) }
  let!(:admin_role) { create(:admin_role) } # factory sets can_edit_users
  let!(:agency) { create :agency }
  let!(:target_role) { create(:role, can_view_clients: true) }
  let(:account_request) { create(:account_request, email: 'newcomer@example.com', first_name: 'New', last_name: 'Comer') }

  before(:each) do
    sign_in admin
    admin.legacy_roles << admin_role
  end

  it 'invites a local user with the requested agency and roles, and records the approver' do
    expect do
      patch admin_account_request_path(account_request), params: {
        account_request: { agency_id: agency.id, role_ids: [target_role.id], access_group_ids: [] },
      }
    end.to change(User, :count).by(1)

    user = User.find_by(email: 'newcomer@example.com')
    expect(user.agency_id).to eq(agency.id)
    expect(user.legacy_roles).to include(target_role)

    account_request.reload
    expect(account_request.status).to eq('accepted')
    expect(account_request.user_id).to eq(user.id)
    expect(account_request.accepted_by).to eq(admin.id)
  end
end
