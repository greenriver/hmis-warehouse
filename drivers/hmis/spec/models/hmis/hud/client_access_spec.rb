###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative '../../../requests/hmis/login_and_permissions'

RSpec.describe Hmis::Hud::Client, type: :model do
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

  let!(:unenrolled_client) { create(:hmis_hud_client, data_source: ds1) }

  let!(:client_at_p1) do
    # Client with non-WIP enrollment at p1
    create(:hmis_hud_client, data_source: ds1, with_enrollment_at: p1)
  end

  let!(:client_at_p2) do
    # Client with WIP enrollment at p2
    client = create(:hmis_hud_client, data_source: ds1, with_enrollment_at: p2)
    client.enrollments.first.save_in_progress!
    client
  end

  let!(:user_with_no_access) { create(:hmis_user, data_source: ds1) }

  let!(:user_with_access_to_p1_clients) do
    hmis_user = create(:hmis_user, data_source: ds1)
    create_access_control(hmis_user, p1, with_permission: [:can_view_clients, :can_view_project])
    hmis_user
  end

  let!(:user_with_access_to_p2_clients) do
    hmis_user = create(:hmis_user, data_source: ds1)
    create_access_control(hmis_user, p2, with_permission: [:can_view_clients, :can_view_project])
    hmis_user
  end

  let!(:user_with_perms_but_no_project_access) do
    hmis_user = create(:hmis_user, data_source: ds1)
    create_access_control(hmis_user, p1, with_permission: [:can_manage_incoming_referrals])
    create_access_control(hmis_user, p2, with_permission: [:can_enroll_clients])
    hmis_user
  end

  let!(:user_with_can_view_clients_but_no_project_access) do
    hmis_user = create(:hmis_user, data_source: ds1)
    create_access_control(hmis_user, p1, with_permission: [:can_view_clients])
    create_access_control(hmis_user, p2, with_permission: [:can_view_clients])
    hmis_user
  end

  describe 'viewable_by scope' do
    it 'is empty if I have no access' do
      viewable_clients = Hmis::Hud::Client.viewable_by(user_with_no_access)
      expect(viewable_clients).to be_empty
    end

    it 'includes clients with enrollments at projects I can see, plus unenrolled clients' do
      # Client with enrollment at p1 + unenrolled
      viewable_clients = Hmis::Hud::Client.viewable_by(user_with_access_to_p1_clients)
      expect(viewable_clients).to contain_exactly(client_at_p1, unenrolled_client)
    end

    it 'includes clients with WIP enrollments at projects I can see, plus unenrolled clients' do
      # Client with enrollment at p2 (WIP) + unenrolled
      viewable_clients = Hmis::Hud::Client.viewable_by(user_with_access_to_p2_clients)
      expect(viewable_clients).to contain_exactly(client_at_p2, unenrolled_client)
    end

    it 'is empty if I dont have can_view_clients, even if I have other perms at projects' do
      # Can't see unenrolled client because doesn't have can_view_clients anywhere
      viewable_clients = Hmis::Hud::Client.viewable_by(user_with_perms_but_no_project_access)
      expect(viewable_clients).to be_empty
    end

    it 'includes clients at projects where I have can_view_clients, even if I cant see those projects' do
      viewable_clients = Hmis::Hud::Client.viewable_by(user_with_can_view_clients_but_no_project_access)
      expect(viewable_clients).to contain_exactly(client_at_p1, client_at_p2, unenrolled_client)
    end
  end
end
