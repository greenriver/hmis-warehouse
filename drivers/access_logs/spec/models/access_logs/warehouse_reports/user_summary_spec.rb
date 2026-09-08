###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AccessLogs::WarehouseReports::UserSummary do
  let(:range) { 10.days.ago.to_date..Date.current }
  subject(:summary) { described_class.new(range: range).call }

  def warehouse_visit(user, visited_at)
    ActivityLog.create!(user: user, path: '/clients', controller_name: 'clients', action_name: 'index', ip_address: '127.0.0.1', created_at: visited_at)
  end

  def grant_warehouse_access(user)
    group = create(:user_group)
    group.add([user])
    create(:access_control, user_group: group, role: create(:role), collection: create(:collection))
  end

  describe 'warehouse access' do
    let(:user) { create(:user, created_at: 1.year.ago) }
    let(:outside_user) { create(:user, created_at: 1.year.ago) }

    it 'reports each user once with first and last access inside the range, ignoring out-of-range visits' do
      first = 3.days.ago.beginning_of_day + 9.hours
      last = 1.day.ago.beginning_of_day + 17.hours
      warehouse_visit(user, first)
      warehouse_visit(user, last)
      warehouse_visit(user, range.begin - 1.day)
      warehouse_visit(outside_user, range.begin - 3.days)

      expect(summary[:access][:warehouse]).to eq([{ user_id: user.id, first_access: first, last_access: last }])
    end

    it 'counts a visit late on the last local day of the range' do
      warehouse_visit(user, range.end.beginning_of_day + 23.hours)

      expect(summary[:access][:warehouse].map { |r| r[:user_id] }).to eq([user.id])
    end

    # Access history is an audit record; it must not disappear when permissions are later revoked.
    it 'still lists a user who has since lost every access control and been deleted' do
      revoked = create(:acl_user, created_at: 1.year.ago)
      access_control = create(:hmis_access_control, with_users: [revoked])
      warehouse_visit(revoked, 2.days.ago)
      create(:hmis_activity_log, user: Hmis::User.find(revoked.id), created_at: 2.days.ago)
      access_control.destroy!
      revoked.user_group_members.destroy_all
      revoked.destroy!

      expect(summary[:access][:warehouse].map { |r| r[:user_id] }).to eq([revoked.id])
      expect(summary[:access][:hmis].map { |r| r[:user_id] }).to eq([revoked.id])
    end
  end

  describe 'HMIS access' do
    let(:hmis_user) { create(:hmis_user, created_at: 1.year.ago) }

    context 'when the HMIS is enabled' do
      let(:data_source) { create(:hmis_data_source) }

      it 'reports HMIS users with first and last access' do
        first = 2.days.ago.noon
        last = 1.day.ago.noon
        create(:hmis_activity_log, user: hmis_user, data_source: data_source, created_at: first)
        create(:hmis_activity_log, user: hmis_user, data_source: data_source, created_at: last)

        expect(summary[:hmis_enabled]).to be(true)
        expect(summary[:access][:hmis]).to eq([{ user_id: hmis_user.id, first_access: first, last_access: last }])
      end
    end

    context 'when the HMIS is disabled' do
      before { allow(HmisEnforcement).to receive(:hmis_enabled?).and_return(false) }

      it 'marks HMIS disabled and reports no HMIS access even if log rows exist' do
        create(:hmis_activity_log, user: hmis_user, created_at: 1.day.ago)

        expect(summary[:hmis_enabled]).to be(false)
        expect(summary[:access][:hmis]).to eq([])
      end
    end
  end

  describe 'users created in range' do
    let!(:both_user) { create(:acl_user, created_at: 2.days.ago) }
    let!(:hmis_only_user) { create(:user, created_at: 3.days.ago) }
    let!(:no_access_user) { create(:user, created_at: 4.days.ago) }
    let!(:old_user) { create(:acl_user, created_at: range.begin - 1.day) }

    before do
      grant_warehouse_access(both_user)
      grant_warehouse_access(old_user)
      create(:hmis_access_control, with_users: [both_user, hmis_only_user])
    end

    it 'lists everyone created in range, flags which access each holds, and counts overlap in both totals' do
      expect(summary[:created][:all]).to eq([
                                              { user_id: both_user.id, created_at: both_user.reload.created_at, warehouse: true, hmis: true },
                                              { user_id: hmis_only_user.id, created_at: hmis_only_user.reload.created_at, warehouse: false, hmis: true },
                                              { user_id: no_access_user.id, created_at: no_access_user.reload.created_at, warehouse: false, hmis: false },
                                            ])
      expect(summary[:created][:warehouse_count]).to eq(1)
      expect(summary[:created][:hmis_count]).to eq(2)
    end
  end
end
