###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# Regression guard: the controller lives in `module Admin`, so an unqualified
# `Idp::ServiceConfig` resolves against the `Admin::Idp` namespace (created by
# Admin::Idp::UsersController) before the top-level `::Idp`. The references must
# stay fully-qualified (`::Idp::...`) or these pages raise
# `uninitialized constant Admin::Idp::ServiceConfig`.
RSpec.describe Admin::IdpServiceConfigsController, type: :request do
  let!(:admin_role) { create :admin_role, can_manage_config: true }
  let!(:collection) { create :collection }
  let!(:admin_user) { create(:acl_user, first_name: 'Admin', last_name: 'User') }

  before(:each) do
    setup_access_control(admin_user, admin_role, collection)
    sign_in admin_user
  end

  it 'renders the index (resolves ::Idp::ServiceConfig)' do
    create(:idp_service_config, connector_id: 'test', provider: 'keycloak')
    get admin_idp_service_configs_path
    expect(response).to have_http_status(200)
  end

  it 'renders the new form (resolves ::Idp::ServiceFactory)' do
    get new_admin_idp_service_config_path
    expect(response).to have_http_status(200)
  end
end
