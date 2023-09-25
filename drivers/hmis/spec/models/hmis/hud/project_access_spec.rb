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

  let!(:user_with_no_access) { create(:hmis_user, data_source: ds1) }

  let!(:user_with_p1_access) do
    hmis_user = create(:hmis_user, data_source: ds1)
    create_access_control(hmis_user, p1, with_permission: :can_view_project)
    hmis_user
  end

  let!(:user_with_p2_access) do
    hmis_user = create(:hmis_user, data_source: ds1)
    # p2 view access
    create_access_control(hmis_user, p2, with_permission: :can_view_project)
    # some other broad org access should still not let you see p1
    create_access_control(hmis_user, o1, with_permission: :can_manage_incoming_referrals)
    hmis_user
  end

  let!(:user_with_limited_access) do
    hmis_user = create(:hmis_user, data_source: ds1)
    create_access_control(hmis_user, o1, with_permission: :can_manage_incoming_referrals)
    hmis_user
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
