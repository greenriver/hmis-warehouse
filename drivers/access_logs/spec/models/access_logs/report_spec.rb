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

  def warehouse_visit(user, visited_at)
    ActivityLog.create!(user: user, path: '/clients', controller_name: 'clients', action_name: 'index', ip_address: '127.0.0.1', created_at: visited_at)
  end

  describe 'sheet row cap' do
    let(:note) { ['Only the first 2 rows are included. Narrow the date range or choose a user to export the rest.'] }

    before { stub_const('AccessLogs::Report::EXPORT_ROW_LIMIT', 2) }

    def sheet_values(name)
      sheet = report.as_excel.workbook.worksheets.find { |ws| ws.name == name }
      sheet.rows.map { |row| row.cells.map(&:value) }
    end

    it 'truncates every sheet to the limit and appends a note' do
      warehouse_user = create(:user)
      3.times { warehouse_visit(warehouse_user, 1.day.ago) }
      hmis_user = create(:hmis_user)
      3.times { create(:hmis_activity_log, user: hmis_user, created_at: 1.day.ago) }

      warehouse = sheet_values('Warehouse')
      hmis = sheet_values('HMIS')

      expect(warehouse.size).to eq(4)
      expect(warehouse[1..2].map(&:first)).to eq([warehouse_user.id, warehouse_user.id])
      expect(warehouse.last).to eq(note)
      expect(hmis.size).to eq(4)
      expect(hmis.last).to eq(note)
    end

    it 'leaves a sheet with exactly the limit alone' do
      warehouse_user = create(:user)
      2.times { warehouse_visit(warehouse_user, 1.day.ago) }

      warehouse = sheet_values('Warehouse')

      expect(warehouse.size).to eq(3)
      expect(warehouse.last.first).to eq(warehouse_user.id)
    end

    it 'skips the CAS sheet when the CAS database is absent' do
      expect(report.as_excel.workbook.worksheets.map(&:name)).not_to include('CAS')
    end
  end

  it 'includes warehouse activity logged late on the last day of the range' do
    late_user = create(:user)
    ActivityLog.create!(user: late_user, path: '/clients', controller_name: 'clients', action_name: 'index', ip_address: '127.0.0.1', created_at: filter.end.beginning_of_day + 23.hours)

    expect(report.sheet_rows['Warehouse'].drop(1).map(&:first)).to eq([late_user.id])
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

      expect(report.sheet_rows['HMIS'].drop(1).map(&:first)).to eq([hmis_user.id])
    end

    it 'includes every HMIS user when no HMIS user is chosen' do
      expect(report.sheet_rows['HMIS'].drop(1).map(&:first)).to contain_exactly(hmis_user.id, other_hmis_user.id)
    end
  end

  context 'when the HMIS is disabled' do
    before { allow(HmisEnforcement).to receive(:hmis_enabled?).and_return(false) }

    it 'has no HMIS sheet even though HMIS log rows exist' do
      create(:hmis_activity_log, created_at: 1.day.ago)

      expect(report.sheet_rows.keys).to contain_exactly('Warehouse', 'CAS')
    end
  end
end
