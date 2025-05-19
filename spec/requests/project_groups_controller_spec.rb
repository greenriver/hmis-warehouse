# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProjectGroupsController, type: :request do
  let!(:user) { create(:user) }
  let!(:project_group) { create(:project_group, name: 'Test Group') }
  let!(:project_group_2) { create(:project_group, name: 'Another Group') }
  let!(:role) { create(:role, can_edit_project_groups: true) }

  before(:each) do
    user.legacy_roles << role
    sign_in user
  end

  describe 'GET #index' do
    it 'lists project groups' do
      get project_groups_path
      expect(response).to have_http_status(:success)
      expect(assigns(:project_groups)).to include(project_group, project_group_2)
    end

    it 'filters project groups by search term' do
      get project_groups_path, params: { q: 'Test' }
      expect(response).to have_http_status(:success)
      expect(assigns(:project_groups)).to include(project_group)
      expect(assigns(:project_groups)).not_to include(project_group_2)
    end
  end
end
