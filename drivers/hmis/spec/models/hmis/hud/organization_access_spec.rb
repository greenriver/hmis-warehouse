###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
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
  let!(:ds2) { create :hmis_data_source }
  let!(:o1) { create :hmis_hud_organization, data_source: ds1 }
  let!(:p1) { create :hmis_hud_project, data_source: ds1, organization: o1 }

  let!(:o2) { create :hmis_hud_organization, data_source: ds1 }
  let!(:p2) { create :hmis_hud_project, data_source: ds1, organization: o2 }

  let!(:o3) { create :hmis_hud_organization, data_source: ds1 }

  let!(:o4) { create :hmis_hud_organization, data_source: ds2 }
  let!(:p4) { create :hmis_hud_project, data_source: ds2, organization: o4 }

  let!(:user_with_no_access) { create(:hmis_user, data_source: ds1) }

  let!(:user_with_ds1_access) do
    hmis_user = create(:hmis_user, data_source: ds1)
    create_access_control(hmis_user, ds1, with_permission: :can_view_project)
    hmis_user
  end

  let!(:user_with_o1_access) do
    hmis_user = create(:hmis_user, data_source: ds1)
    create_access_control(hmis_user, o1, with_permission: :can_view_project) # access to view o1
    create_access_control(hmis_user, o2, with_permission: :can_view_enrollment_details) # should not grant any access
    hmis_user
  end

  let!(:user_with_p2_access) do
    hmis_user = create(:hmis_user, data_source: ds1)
    create_access_control(hmis_user, p2, with_permission: :can_view_project) # access to view p2
    create_access_control(hmis_user, o3, with_permission: :can_view_enrollment_details) # should not grant any access
    hmis_user
  end

  let!(:user_with_ds1_and_ds2_access) do
    hmis_user = create(:hmis_user, data_source: ds1)
    create_access_control(hmis_user, ds1)
    create_access_control(hmis_user, ds2)
    hmis_user
  end

  describe 'viewable_by scope' do
    it 'includes organizations where use has can_view_project (data source)' do
      viewable_orgs = Hmis::Hud::Organization.viewable_by(user_with_ds1_access)
      expect(viewable_orgs).to contain_exactly(o1, o2, o3)
    end

    it 'includes organizations where use has can_view_project (organization-level)' do
      viewable_orgs = Hmis::Hud::Organization.viewable_by(user_with_o1_access)
      expect(viewable_orgs).to contain_exactly(o1)
    end

    it 'includes organizations where use has can_view_project (project-level)' do
      viewable_orgs = Hmis::Hud::Organization.viewable_by(user_with_p2_access)
      expect(viewable_orgs).to contain_exactly(o2)
    end

    it 'includes only organizations associated with the data source ID of the current user' do
      viewable_orgs = Hmis::Hud::Organization.viewable_by(user_with_ds1_and_ds2_access)
      expect(viewable_orgs).to contain_exactly(o1, o2, o3)

      # change hmis_data_source_id to ds2 to ensure it can access o4
      user_with_ds1_and_ds2_access.hmis_data_source_id = ds2.id
      viewable_orgs = Hmis::Hud::Organization.viewable_by(user_with_ds1_and_ds2_access)
      expect(viewable_orgs).to contain_exactly(o4)
    end
  end
end
