###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AccessLogs::Report do
  # The export job clears user_id when "All" warehouse users are requested; FilterBase needs one to construct.
  let(:filter) { ::Filters::FilterBase.new(user_id: create(:user).id, start: 5.days.ago.to_date, end: Date.current).tap { |f| f.user_id = nil } }
  let(:report) { described_class.new(filter: filter) }

  it 'includes warehouse activity logged late on the last day of the range' do
    late_user = create(:user)
    ActivityLog.create!(user: late_user, path: '/clients', controller_name: 'clients', action_name: 'index', ip_address: '127.0.0.1', created_at: filter.end.beginning_of_day + 23.hours)

    expect(report.data['Warehouse'].drop(1).map(&:first)).to eq([late_user.id])
  end

  context 'when the HMIS is enabled' do
    let(:data_source) { create(:hmis_data_source) }
    let(:hmis_user) { create(:hmis_user) }
    let(:other_hmis_user) { create(:hmis_user) }

    before do
      create(:hmis_activity_log, user: hmis_user, data_source: data_source, created_at: 1.day.ago)
      create(:hmis_activity_log, user: other_hmis_user, data_source: data_source, created_at: 1.day.ago)
    end

    it 'adds an HMIS sheet limited to the chosen HMIS user' do
      report.hmis_user_id = hmis_user.id

      expect(report.data['HMIS'].drop(1).map(&:first)).to eq([hmis_user.id])
    end

    it 'includes every HMIS user when no HMIS user is chosen' do
      expect(report.data['HMIS'].drop(1).map(&:first)).to contain_exactly(hmis_user.id, other_hmis_user.id)
    end
  end

  context 'when the HMIS is disabled' do
    before { allow(HmisEnforcement).to receive(:hmis_enabled?).and_return(false) }

    it 'has no HMIS sheet even though HMIS log rows exist' do
      create(:hmis_activity_log, created_at: 1.day.ago)

      expect(report.data.keys).to contain_exactly('Warehouse', 'CAS')
    end
  end
end
