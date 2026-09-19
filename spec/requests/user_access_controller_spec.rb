###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserAccessController, type: :request do
  let(:user) { create(:acl_user) }
  let(:role) { create(:role, can_view_projects: true) }
  let(:collection) { create(:collection) }
  let(:data_source) { create(:source_data_source) }

  # Distinct role names matter here: setup_access_control keys its UserGroup lookup by
  # "#{role.name} x #{collection.name}" - two same-named roles sharing a collection
  # would collapse into one UserGroup, and its members would inherit both roles.
  let!(:viewer_role) { create(:role, name: 'viewer_role', can_view_clients: true) }
  let!(:non_viewing_role) { create(:role, name: 'non_viewing_role', can_view_clients: false) }
  let!(:viewer) { create(:acl_user, first_name: 'Vivian', last_name: 'Viewer') }
  let!(:wrong_role_user) { create(:acl_user, first_name: 'Wanda', last_name: 'WrongRole') }

  before do
    covering_collection = create(:collection)
    covering_collection.set_viewables({ data_sources: [data_source.id] })
    setup_access_control(viewer, viewer_role, covering_collection)
    setup_access_control(wrong_role_user, non_viewing_role, covering_collection)
  end

  describe 'GET #show' do
    it 'redirects unauthenticated users to sign in' do
      expect_unauthenticated_warehouse_request do
        get data_source_user_access_path(data_source)
      end
    end

    it 'denies users who cannot view projects, organizations, or imports' do
      sign_in create(:acl_user)
      get data_source_user_access_path(data_source)
      expect(response).to redirect_to(root_path)
    end

    it 'lists only users with view access, for a user who can view the data source' do
      collection.set_viewables({ data_sources: [data_source.id] })
      setup_access_control(user, role, collection)
      sign_in user

      get data_source_user_access_path(data_source)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Vivian Viewer')
      expect(response.body).not_to include('Wanda WrongRole')
    end

    it 'does not serve the modal for a data source the user cannot view' do
      # Grants general view permission via an unrelated, empty collection, so the
      # 404 below is attributable to data-source scoping, not the permission gate.
      setup_access_control(user, role, create(:collection))
      sign_in user
      get data_source_user_access_path(data_source)
      expect(response).to have_http_status(:not_found)
    end
  end
end
