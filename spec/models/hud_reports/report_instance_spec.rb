# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HudReports::ReportInstance, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  describe '#start_report' do
    after { travel_back }

    it 'accumulates elapsed time from previous runs in checkpoints' do
      travel_to Time.zone.parse('2025-01-01 12:00:00') do
        report = described_class.create!(
          report_name: 'Test Report',
          state: 'Started',
          # Started 1 hour ago
          started_at: 1.hour.ago,
          # One finished checkpoint of 30 mins
          checkpoints: [
            { 'name' => 'Init', 'started_at' => 1.hour.ago.iso8601, 'completed_at' => 30.minutes.ago.iso8601 },
          ],
          question_names: ['test'],
        )

        # Resume execution (start_report)
        report.start_report

        # Checkpoints should not change just by starting (no default checkpoint now)
        expect(report.checkpoints.size).to eq(1)

        # Original started_at should remain unchanged
        expect(report.started_at).to eq(1.hour.ago)

        # Advance 10 minutes
        travel 10.minutes

        # Checkpoint progress
        report.track_progress('Q1') do
          # Inside block
          expect(report.checkpoints.size).to eq(2)
          expect(report.checkpoints.last['name']).to eq('Q1')
          expect(report.checkpoints.last['started_at']).to eq(Time.current.iso8601)

          # Advance 5 minutes
          travel 5.minutes
        end

        # Reload to see persisted checkpoint
        report.reload
        expect(report.checkpoints.last['completed_at']).to eq(Time.current.iso8601)

        # Total duration:
        # Segment 1: 30 mins
        # Segment 2: 5 mins
        # Total: 35 mins

        expect(report.total_duration_in_words).to eq('35 minutes')
      end
    end
  end

  describe '#total_duration_in_words' do
    after { travel_back }

    it 'handles multiple sequential checkpoints' do
      travel_to Time.zone.parse('2025-01-01 12:00:00') do
        base_time = Time.current
        report = described_class.create!(
          report_name: 'Test Report',
          state: 'Completed',
          started_at: base_time,
          checkpoints: [
            { 'name' => 'Prep', 'started_at' => base_time.iso8601, 'completed_at' => (base_time + 10.minutes).iso8601 },
            { 'name' => 'Q1', 'started_at' => (base_time + 10.minutes).iso8601, 'completed_at' => (base_time + 25.minutes).iso8601 },
            { 'name' => 'Q2', 'started_at' => (base_time + 25.minutes).iso8601, 'completed_at' => (base_time + 45.minutes).iso8601 },
          ],
          question_names: ['test'],
        )

        # Total: 10 + 15 + 20 = 45 minutes
        expect(report.total_duration_in_words).to eq('about 1 hour')
      end
    end

    it 'excludes crashed checkpoints from duration' do
      travel_to Time.zone.parse('2025-01-01 12:00:00') do
        base_time = Time.current
        report = described_class.create!(
          report_name: 'Test Report',
          state: 'Failed',
          started_at: base_time,
          checkpoints: [
            { 'name' => 'Prep', 'started_at' => base_time.iso8601, 'completed_at' => (base_time + 10.minutes).iso8601 },
            { 'name' => 'Q1', 'started_at' => (base_time + 10.minutes).iso8601 }, # Crashed - no completed_at
          ],
          question_names: ['test'],
        )

        # Only counts completed checkpoint: 10 minutes
        expect(report.total_duration_in_words).to eq('10 minutes')
      end
    end

    it 'includes active checkpoint when report is running' do
      travel_to Time.zone.parse('2025-01-01 12:00:00') do
        base_time = Time.current
        report = described_class.create!(
          report_name: 'Test Report',
          state: 'Started',
          started_at: base_time,
          checkpoints: [
            { 'name' => 'Prep', 'started_at' => base_time.iso8601, 'completed_at' => (base_time + 10.minutes).iso8601 },
            { 'name' => 'Q1', 'started_at' => (base_time + 10.minutes).iso8601 }, # Active checkpoint
          ],
          question_names: ['test'],
        )

        # Stub related_job so running? returns true
        fake_job = double('Delayed::Job', failed?: false)
        allow(report).to receive(:related_job).and_return(fake_job)

        travel 20.minutes

        # Need to reload to ensure running? check works correctly with traveled time
        report.reload
        # Re-stub after reload
        allow(report).to receive(:related_job).and_return(fake_job)

        # Prep: 10 minutes + Q1: 10 minutes (from start to current) = 20 minutes
        expect(report.total_duration_in_words).to eq('20 minutes')
      end
    end

    it 'returns nil when started_at is not set' do
      report = described_class.create!(
        report_name: 'Test Report',
        state: 'Queued',
        checkpoints: [],
        question_names: ['test'],
      )

      expect(report.total_duration_in_words).to be_nil
    end

    it 'returns zero duration for empty checkpoints array' do
      travel_to Time.zone.parse('2025-01-01 12:00:00') do
        report = described_class.create!(
          report_name: 'Test Report',
          state: 'Started',
          started_at: 1.hour.ago,
          checkpoints: [],
          question_names: ['test'],
        )

        expect(report.total_duration_in_words).to eq('less than a minute')
      end
    end
  end
end
