###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative '../../../requests/hmis/login_and_permissions'

RSpec.describe Hmis::Hud::Project, type: :model do
  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  let!(:ds1) { create :hmis_data_source }
  let!(:o1) { create :hmis_hud_organization, data_source: ds1 }
  let!(:p1) { create :hmis_hud_project, data_source: ds1, organization: o1 }
  let!(:p2) { create :hmis_hud_project, data_source: ds1, organization: o1 }

  # Roles
  let!(:project_viewer) { create(:hmis_role_with_no_permissions, name: 'project viewer', can_view_project: true) }
  let!(:client_viewer) { create(:hmis_role_with_no_permissions, name: 'client viewer', can_view_clients: true) }

  # Collections
  let!(:p1_collection) { create(:hmis_access_group, name: 'p1 collection', with_entities: p1) }
  let!(:p2_collection) { create(:hmis_access_group, name: 'p2 collection', with_entities: p2) }
  let!(:ds1_collection) { create(:hmis_access_group, name: 'ds1 collection', with_entities: ds1) }

  let!(:user_with_no_access) { create(:hmis_user, data_source: ds1) }

  let!(:user_with_ds1_access) do
    user = create(:hmis_user, data_source: ds1)
    create(:hmis_access_control, role: project_viewer, access_group: ds1_collection, with_users: user)
    user
  end

  let!(:user_with_p1_access) do
    user = create(:hmis_user, data_source: ds1)
    create(:hmis_access_control, role: project_viewer, access_group: p1_collection, with_users: user)
    user
  end

  let!(:user_with_p2_access) do
    user = create(:hmis_user, data_source: ds1)
    # p2 view access
    create(:hmis_access_control, role: project_viewer, access_group: p2_collection, with_users: user)
    # some other broad org access should still not let you see p1
    create(:hmis_access_control, role: client_viewer, access_group: ds1_collection, with_users: user)
    user
  end

  let!(:user_with_limited_access) do
    user = create(:hmis_user, data_source: ds1)
    create(:hmis_access_control, role: client_viewer, access_group: ds1_collection, with_users: user)
    user
  end

  describe 'viewable_by scope' do
    it 'includes projects where I have can_view_project' do
      viewable_projects = Hmis::Hud::Project.viewable_by(user_with_p1_access)
      expect(viewable_projects).to contain_exactly(p1)

      viewable_projects = Hmis::Hud::Project.viewable_by(user_with_p2_access)
      expect(viewable_projects).to contain_exactly(p2)
    end

    it 'excludes projects where I dont have can_view_project, even if I have other permissions there' do
      viewable_projects = Hmis::Hud::Project.viewable_by(user_with_limited_access)
      expect(viewable_projects).to be_empty
    end
  end
end
