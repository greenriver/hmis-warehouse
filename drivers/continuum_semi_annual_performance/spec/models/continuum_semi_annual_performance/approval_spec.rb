###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContinuumSemiAnnualPerformance::Approval, type: :model do
  let(:user) { create(:acl_user) }
  let(:approver) { create(:acl_user) }
  let(:report) { ContinuumSemiAnnualPerformance::EndOfYearReport.create!(user_id: user.id, options: { coc_codes: ['XX-500'] }) }

  it 'is pending before anyone approves' do
    expect(report.approvals.exists?).to be(false)
    expect(report.approved?).to be(false)
  end

  it 'records the approving user, not the report owner' do
    approval = report.approve!(user: approver, approved: true)

    expect(approval.reload.user_id).to eq(approver.id)
    expect(approval.user_id).not_to eq(report.user_id)
  end

  it 'keeps every approve and unapprove, newest deciding the state' do
    travel_to(Time.zone.local(2027, 1, 9, 14)) { report.approve!(user: user, approved: true) }
    travel_to(Time.zone.local(2027, 1, 10, 9)) { report.approve!(user: approver, approved: false) }

    expect(report.approved?).to be(false)
    travel_to(Time.zone.local(2027, 1, 12, 15)) { report.approve!(user: user, approved: true) }

    expect(report.approvals.newest_first.map(&:action_label)).to eq(['Approved', 'Approval Removed', 'Approved'])
    expect(report.approved?).to be(true)
  end

  it 'adds no row when approving an approved report' do
    report.approve!(user: user, approved: true)

    expect { report.approve!(user: approver, approved: true) }.not_to change(report.approvals, :count)
  end

  it 'adds no row when unapproving a report that was never approved' do
    expect { report.approve!(user: user, approved: false) }.not_to change(report.approvals, :count)
  end

  it 'adds no row when unapproving an already unapproved report' do
    report.approve!(user: user, approved: true)
    report.approve!(user: user, approved: false)

    expect { report.approve!(user: approver, approved: false) }.not_to change(report.approvals, :count)
  end

  it 'cannot be edited after saving' do
    approval = report.approve!(user: user, approved: true)

    expect { approval.update!(approved: false) }.to raise_error(ActiveRecord::ReadOnlyRecord)
  end
end
