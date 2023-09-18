###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative '../../../requests/hmis/login_and_permissions'

RSpec.describe Hmis::Hud::Enrollment, type: :model do
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
  let!(:p3) { create :hmis_hud_project, data_source: ds1, organization: o1 }
  let!(:p4) { create :hmis_hud_project, data_source: ds1, organization: o1 }
  let!(:p5) { create :hmis_hud_project, data_source: ds1, organization: o1 }
  let!(:p6) { create :hmis_hud_project, data_source: ds1, organization: o1 }

  let!(:c1) { create(:hmis_hud_client, data_source: ds1) }

  let!(:e1) { create(:hmis_hud_enrollment, client: c1, project: p1, data_source: ds1) }
  let!(:e2) { create(:hmis_hud_wip_enrollment, client: c1, project: p2, data_source: ds1) }
  let!(:e3) { create(:hmis_hud_enrollment, client: c1, project: p3, data_source: ds1) }
  let!(:e4) { create(:hmis_hud_enrollment, client: c1, project: p4, data_source: ds1) }
  let!(:e5) { create(:hmis_hud_enrollment, client: c1, project: p5, data_source: ds1) }
  let!(:e6) { create(:hmis_hud_enrollment, client: c1, project: p6, data_source: ds1) }

  let!(:user_with_no_access) { create(:hmis_user, data_source: ds1) }

  let!(:user_with_p1_p2_access) do
    hmis_user = create(:hmis_user, data_source: ds1)
    # p1: can see enrollments
    create_access_control(hmis_user, p1, with_permission: [:can_view_clients, :can_view_project, :can_view_enrollment_details])
    # p2: can see enrollments
    create_access_control(hmis_user, p2, with_permission: [:can_view_clients, :can_view_project, :can_view_enrollment_details])
    # p3: can see project, but not enrollments
    create_access_control(hmis_user, p3, with_permission: [:can_view_clients, :can_view_project])
    # p4: no project access
    create_access_control(hmis_user, p4, with_permission: [:can_view_enrollment_details])
    # p5: no project access, no enrollment access
    create_access_control(hmis_user, p4, with_permission: [:can_view_clients])
    hmis_user
  end

  describe 'viewable_by scope' do
    it 'is empty if I have no access' do
      viewable_enrollments = Hmis::Hud::Enrollment.viewable_by(user_with_no_access)
      expect(viewable_enrollments).to be_empty
    end

    it 'includes enrollments that I can see (WIP and non-WIP), and excludes ones I cant see' do
      viewable_enrollments = Hmis::Hud::Enrollment.viewable_by(user_with_p1_p2_access)
      expect(viewable_enrollments).to contain_exactly(e1, e2)
      # e3 not visible because user lacks :can_view_enrollment_details
      # e4 not visible because user lacks :can_view_project
      # e5 not visible because user lacks both :can_view_enrollment_details and :can_view_project
      # e6 not visible because user lacks any assignment
    end
  end
end
