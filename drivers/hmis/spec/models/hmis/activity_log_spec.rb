###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::ActivityLog, type: :model do
  let(:data_source) { create(:hmis_data_source) }
  let(:user) { create(:hmis_user, first_name: 'Ada', last_name: 'Lovelace') }
  let(:other_user) { create(:hmis_user) }
  let(:range) { 5.days.ago.to_date..Date.current }

  def log(user:, visited_at:, **attrs)
    create(:hmis_activity_log, user: user, data_source: data_source, created_at: visited_at, **attrs)
  end

  describe '.created_in_range' do
    it 'includes activity late on the last local day and excludes activity late on the day before the range' do
      included = log(user: user, visited_at: range.end.beginning_of_day + 23.hours)
      log(user: user, visited_at: range.begin.beginning_of_day - 1.hour)

      expect(described_class.created_in_range(range: range)).to contain_exactly(included)
    end
  end

  describe '.to_a' do
    it 'returns a header row followed by one row per log for the requested user, scrubbed of query strings' do
      log(user: user, visited_at: 1.day.ago, operation_name: 'GetClient', header_page_path: '/client/1/profile?tab=x', ip_address: '10.0.0.1', session_hash: 'abc', referer: 'https://hmis.test/clients?q=1')
      log(user: other_user, visited_at: 1.day.ago)

      rows = described_class.to_a(user_id: user.id, range: range.begin.beginning_of_day..range.end.end_of_day)

      expect(rows.first).to eq(['HMIS User ID', 'Data Source', 'Operation', 'Page', 'Access Time', 'Session', 'IP Address', 'Referrer'])
      expect(rows.drop(1).map(&:first)).to eq([user.id])
      expect(rows.last[1..3]).to eq([data_source.name, 'GetClient', '/client/1/profile'])
      expect(rows.last[7]).to eq('https://hmis.test/clients')
    end

    it 'includes every user when user_id is nil and excludes logs outside the range' do
      log(user: user, visited_at: 1.day.ago)
      log(user: other_user, visited_at: 1.day.ago)
      log(user: user, visited_at: range.begin - 2.days)

      rows = described_class.to_a(range: range.begin.beginning_of_day..range.end.end_of_day)

      expect(rows.drop(1).map(&:first)).to contain_exactly(user.id, other_user.id)
    end
  end
end
