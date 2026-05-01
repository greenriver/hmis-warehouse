###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../requests/hmis/login_and_permissions'

RSpec.describe Hmis::Hud::Client, type: :model do
  let!(:ds1) { create :hmis_primary_data_source }
  let!(:ds2) { create :hmis_data_source }
  let!(:o1) { create :hmis_hud_organization, data_source: ds1 }
  let!(:p1) { create :hmis_hud_project, data_source: ds1, organization: o1 }
  let!(:p2) { create :hmis_hud_project, data_source: ds1, organization: o1 }

  let!(:unenrolled_client) { create(:hmis_hud_client, data_source: ds1) }
  let!(:unenrolled_client_at_ds2) { create(:hmis_hud_client, data_source: ds2) }

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

  let!(:user_with_ds1_and_ds2_access) do
    hmis_user = create(:hmis_user, data_source: ds2) # logged in at ds2
    create_access_control(hmis_user, ds1, with_permission: [:can_view_clients]) # BUT can only view clients in ds1
    create_access_control(hmis_user, ds2, with_permission: [:can_view_project]) # can do something else in ds2 (not view clients)
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

    it 'does not include unenrolled clients when I only have access in a different data source' do
      viewable_clients = Hmis::Hud::Client.viewable_by(user_with_ds1_and_ds2_access)
      expect(viewable_clients).to be_empty
    end

    context 'with many clients' do
      before do
        30.times do |i|
          c = create :hmis_hud_client, data_source: ds1
          create :hmis_hud_enrollment, client: c, data_source: ds1, project: p1, entry_date: 1.month.ago if i.even? # half of them have enrollments
        end
      end

      it 'makes a reasonable number of db queries' do
        expect do
          Hmis::Hud::Client.viewable_by(user_with_access_to_p1_clients)
        end.to make_database_queries(count: 15..25)
      end
    end
  end

  describe 'files_viewable_by scope' do
    let(:file_perms) do
      [
        :can_view_any_nonconfidential_client_files,
        :can_view_any_confidential_client_files,
        :can_view_clients,
        :can_view_project,
      ]
    end

    it 'is empty when user has no access' do
      expect(Hmis::Hud::Client.files_viewable_by(user_with_no_access)).to be_empty
    end

    it 'is empty when user has can_view_clients but no file permissions' do
      expect(Hmis::Hud::Client.files_viewable_by(user_with_access_to_p1_clients)).to be_empty
    end

    it 'includes enrolled and unenrolled clients when user has file permissions at a project' do
      hmis_user = create(:hmis_user, data_source: ds1)
      create_access_control(hmis_user, p1, with_permission: file_perms)

      viewable = Hmis::Hud::Client.files_viewable_by(hmis_user)
      expect(viewable).to contain_exactly(client_at_p1, unenrolled_client)
    end

    it 'is empty when user only has file permissions in a different data source' do
      hmis_user = create(:hmis_user, data_source: ds1) # logged in at ds1
      create_access_control(hmis_user, ds2, with_permission: file_perms)
      expect(Hmis::Hud::Client.files_viewable_by(hmis_user)).to be_empty
    end
  end

  describe 'own_files_viewable_by scope' do
    it 'is empty when user has no access' do
      expect(Hmis::Hud::Client.own_files_viewable_by(user_with_no_access)).to be_empty
    end

    it 'is empty when user has can_view_clients but not can_manage_own_client_files' do
      expect(Hmis::Hud::Client.own_files_viewable_by(user_with_access_to_p1_clients)).to be_empty
    end

    it 'includes enrolled and unenrolled clients when user has manage-own at a project' do
      hmis_user = create(:hmis_user, data_source: ds1)
      create_access_control(hmis_user, p1, with_permission: [:can_manage_own_client_files])

      viewable = Hmis::Hud::Client.own_files_viewable_by(hmis_user)
      expect(viewable).to contain_exactly(client_at_p1, unenrolled_client)
    end

    it 'is empty when user only has can_manage_own_client_files in a different data source' do
      hmis_user = create(:hmis_user, data_source: ds1)
      create_access_control(hmis_user, ds2, with_permission: [:can_manage_own_client_files])
      expect(Hmis::Hud::Client.own_files_viewable_by(hmis_user)).to be_empty
    end
  end
end
