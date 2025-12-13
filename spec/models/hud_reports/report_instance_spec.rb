# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HudReports::ReportInstance, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  describe '#start_report' do
    after { travel_back }

    it 'accumulates elapsed time from previous runs before restarting' do
      travel_to Time.zone.parse('2025-01-01 12:10:00') do
        report = described_class.create!(
          report_name: 'Test Report',
          state: 'Started',
          started_at: 10.minutes.ago,
          previous_duration: 30,
          question_names: ['test'],
        )

        # Simulate last activity occurring 5 minutes after the run began
        report.update_column(:updated_at, 5.minutes.ago)

        report.start_report

        expect(report.previous_duration).to eq(30 + 5.minutes.to_i)
        expect(report.started_at).to be_within(1.second).of(Time.zone.parse('2025-01-01 12:10:00'))
      end
    end
  end
end
