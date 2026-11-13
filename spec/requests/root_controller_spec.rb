###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RootController, type: :request do
  it 'renders the sign-in page as HTML' do
    get root_path
    expect(response).to have_http_status(:ok)
  end

  it 'returns 406 for a JSON request instead of raising a missing template error' do
    get root_path, headers: { 'Accept' => 'application/json' }
    expect(response).to have_http_status(:not_acceptable)
  end

  describe 'when signed in' do
    let(:user) { create(:acl_user) }

    before { sign_in user }

    it 'redirects a user with report access to their landing page' do
      setup_access_control(user, create(:role, can_view_all_hud_reports: true), create(:collection))

      get root_path
      expect(response).to redirect_to(warehouse_reports_path)
    end

    it 'renders the access-limited page for a user with no landing page' do
      get root_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Access Limited')
    end
  end
end
