###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PublicReports::StateDashboard, type: :model do
  let(:owner) { create(:acl_user) }
  let(:report) do
    report = described_class.new(
      user: owner,
      filter: { filters: { start: Date.parse('2024-01-01'), end: Date.parse('2025-12-31') } },
    )
    report.save!(validate: false)
    report
  end

  it 'scopes the filter to the owner after the owner is deleted' do
    report
    owner.destroy

    expect(report.reload.filter_object.user).to eq(owner)
  end

  it 'raises instead of choosing another user when the report has no owner' do
    report.update_column(:user_id, nil)

    expect { report.reload.filter_object }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
