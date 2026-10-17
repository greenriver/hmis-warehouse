###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PublicReports::StateDashboard, type: :model do
  let(:report) do
    report = described_class.new(
      user: create(:acl_user),
      filter: { filters: { start: Date.parse('2024-01-01'), end: Date.parse('2025-08-31') } },
    )
    report.save!(validate: false)
    report
  end

  [['quarter', Date.parse('2025-06-30')], ['year', Date.parse('2024-12-31')]].each do |iteration_type, earlier_end|
    it "ends the last #{iteration_type} on the report end date and earlier ones on their own last day" do
      PublicReports::Setting.first_or_create.update!(iteration_type: iteration_type)
      ends = report.iteration_dates.map { |date| report.end_iteration(date) }

      expect([ends.last, ends[-2]]).to eq([Date.parse('2025-08-31'), earlier_end])
    end
  end

  context 'when the report starts partway through a period' do
    before { report.update!(filter: { filters: { start: Date.parse('2024-09-01'), end: Date.parse('2025-08-31') } }) }

    it 'starts at the next quarter and keeps the partial last quarter, ending it on the report end date' do
      PublicReports::Setting.first_or_create.update!(iteration_type: 'quarter')
      dates = report.iteration_dates

      expect([dates, report.end_iteration(dates.last)]).to eq(
        [['2024-10-01', '2025-01-01', '2025-04-01', '2025-07-01'].map { |d| Date.parse(d) }, Date.parse('2025-08-31')],
      )
    end

    it 'starts at the next year and keeps the partial last year, ending it on the report end date' do
      PublicReports::Setting.first_or_create.update!(iteration_type: 'year')
      dates = report.iteration_dates

      expect([dates, report.end_iteration(dates.last)]).to eq([[Date.parse('2025-01-01')], Date.parse('2025-08-31')])
    end
  end
end
