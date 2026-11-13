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
# Runs under whichever AUTH_METHOD the suite is booted with, and both halves are load-bearing: a
# Devise-arm run cannot catch a regression in the JWT half, since admin_user_locations_path is
# defined either way there.
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

  describe 'client page titles' do
    let(:restricted_client) { create(:authoritative_hud_client) }
    let(:other_client) { create(:authoritative_hud_client) }

    def log_visit(path:, title:, item_id:, minutes_ago:)
      ActivityLog.create!(
        user: target_user,
        item_model: 'GrdaWarehouse::Hud::Client',
        item_id: item_id,
        controller_name: 'clients',
        action_name: 'show',
        ip_address: '127.0.0.1',
        path: path,
        title: title,
        created_at: minutes_ago.minutes.ago,
      )
    end

    def item_titles
      Nokogiri::HTML(response.body).css('table tbody tr').map { |tr| tr.css('td')[1].text.strip }
    end

    before do
      log_visit(path: "/clients/#{restricted_client.id}", title: 'Jane Doe', item_id: restricted_client.id, minutes_ago: 1)
      # item_id is the file id on nested pages, so only the path names the client.
      log_visit(path: "/clients/#{restricted_client.id}/files/#{other_client.id}", title: 'Jane Doe - Files', item_id: other_client.id, minutes_ago: 2)
      log_visit(path: "/clients/#{other_client.id}", title: 'John Roe', item_id: other_client.id, minutes_ago: 3)
      Hmis::RestrictedRecord.create!(
        restrictable_id: restricted_client.id,
        restrictable_type: Hmis::RestrictedRecord::CLIENT_RESTRICTABLE_TYPE,
        data_source_id: restricted_client.data_source_id,
        created_by: Hmis::User.find(admin_user.id),
      )
    end

    it 'hides the name logged for a client restricted since the visit, keeping the name for an unrestricted client' do
      get admin_user_audit_path(target_user)

      expect(item_titles).to eq(['Name Redacted', 'Name Redacted - Files', 'John Roe'])
    end
  end
end
