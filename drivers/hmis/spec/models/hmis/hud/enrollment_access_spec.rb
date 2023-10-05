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

  let!(:csc1) { create :hmis_custom_service_category, data_source: ds1 }
  let!(:cst1) { create :hmis_custom_service_type_for_hud_service, data_source: ds1, custom_service_category: csc1 }
  let!(:s1) { create :hmis_hud_service, data_source: ds1, enrollment: e1 }
  let!(:cs1) { create :hmis_custom_service, data_source: ds1, enrollment: e1 }
  # service on wip e2 probably doesn't make sense
  # let!(:s2) { create :hmis_hud_service, data_source: ds1, enrollment: e2 }
  let!(:s3) { create :hmis_hud_service, data_source: ds1, enrollment: e3 }
  let!(:cs3) { create :hmis_custom_service, data_source: ds1, enrollment: e3 }
  let!(:s4) { create :hmis_hud_service, data_source: ds1, enrollment: e4 }
  let!(:cs4) { create :hmis_custom_service, data_source: ds1, enrollment: e4 }
  let!(:s5) { create :hmis_hud_service, data_source: ds1, enrollment: e5 }
  let!(:cs5) { create :hmis_custom_service, data_source: ds1, enrollment: e5 }
  let!(:s6) { create :hmis_hud_service, data_source: ds1, enrollment: e6 }
  let!(:cs6) { create :hmis_custom_service, data_source: ds1, enrollment: e6 }

  # Roles
  let!(:project_viewer) { create(:hmis_role_with_no_permissions, name: 'project viewer', can_view_project: true) }
  let!(:enrollment_viewer) { create(:hmis_role_with_no_permissions, name: 'enrollment viewer', can_view_project: true, can_view_enrollment_details: true) }
  let!(:enrollment_viewer_without_project) { create(:hmis_role_with_no_permissions, name: 'only enrollment viewer', can_view_enrollment_details: true) }
  let!(:client_viewer) { create(:hmis_role_with_no_permissions, name: 'client viewer', can_view_clients: true) }

  # Collections
  let!(:p1_collection) { create(:hmis_access_group, name: 'p1 collection', with_entities: p1) }
  let!(:p2_collection) { create(:hmis_access_group, name: 'p2 collection', with_entities: p2) }
  let!(:p3_collection) { create(:hmis_access_group, name: 'p3 collection', with_entities: p3) }
  let!(:p4_collection) { create(:hmis_access_group, name: 'p4 collection', with_entities: p4) }
  let!(:ds1_collection) { create(:hmis_access_group, name: 'ds1 collection', with_entities: ds1) }

  let!(:user_with_no_access) { create(:hmis_user, data_source: ds1) }

  let!(:user_with_p1_p2_access) do
    user = create(:hmis_user, data_source: ds1)
    # p1: can see enrollments
    create(:hmis_access_control, role: enrollment_viewer, access_group: p1_collection, with_users: user)
    # p2: can see enrollments
    create(:hmis_access_control, role: enrollment_viewer, access_group: p2_collection, with_users: user)
    # p3: can see project, but not enrollments
    create(:hmis_access_control, role: project_viewer, access_group: p3_collection, with_users: user)
    # p4: no project access
    create(:hmis_access_control, role: enrollment_viewer_without_project, access_group: p4_collection, with_users: user)
    # data source: client visibility
    create(:hmis_access_control, role: client_viewer, access_group: ds1_collection, with_users: user)
    user
  end

  let!(:user_with_full_access) do
    user = create(:hmis_user, data_source: ds1)
    create(:hmis_access_control, role: enrollment_viewer, access_group: ds1_collection, with_users: user)
    user
  end

  describe 'viewable_by scope' do
    it 'enrollments are empty if I have no access' do
      viewable_enrollments = Hmis::Hud::Enrollment.viewable_by(user_with_no_access)
      expect(viewable_enrollments).to be_empty
    end

    it 'services are empty if I have no access' do
      viewable = Hmis::Hud::HmisService.viewable_by(user_with_no_access)
      expect(viewable).to be_empty
    end

    it 'households are empty if I have no access' do
      viewable = Hmis::Hud::Household.viewable_by(user_with_no_access)
      expect(viewable).to be_empty
    end

    it 'includes all enrollments for user with full data source access' do
      viewable_enrollments = Hmis::Hud::Enrollment.viewable_by(user_with_full_access)
      expect(viewable_enrollments).to contain_exactly(e1, e2, e3, e4, e5, e6)
    end

    it 'includes all services for user with full data source access' do
      viewable = Hmis::Hud::HmisService.viewable_by(user_with_full_access).map(&:owner)
      expect(viewable).to contain_exactly(s1, s3, s4, s5, s6, cs1, cs3, cs4, cs5, cs6)
    end

    it 'includes all households for user with full data source access' do
      viewable = Hmis::Hud::Household.viewable_by(user_with_full_access).pluck(:household_id)
      expect(viewable).to contain_exactly(*[e1, e2, e3, e4, e5, e6].map(&:household_id))
    end

    it 'includes enrollments that I can see (WIP and non-WIP), and excludes ones I cant see' do
      viewable_enrollments = Hmis::Hud::Enrollment.viewable_by(user_with_p1_p2_access)
      expect(viewable_enrollments).to contain_exactly(e1, e2)
      # e3 not visible because user lacks :can_view_enrollment_details
      # e4 not visible because user lacks :can_view_project
      # e5 not visible because user lacks both :can_view_enrollment_details and :can_view_project
      # e6 not visible because user lacks any assignment
    end

    it 'includes services that I can see, and excludes ones I cant see' do
      viewable = Hmis::Hud::HmisService.viewable_by(user_with_p1_p2_access).map(&:owner)
      expect(viewable).to contain_exactly(s1, cs1)
    end

    it 'includes households that I can see, and excludes ones I cant see' do
      viewable = Hmis::Hud::Household.viewable_by(user_with_p1_p2_access).pluck(:household_id)
      expect(viewable).to contain_exactly(e1.household_id, e2.household_id)
    end
  end
end
