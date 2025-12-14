# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HudReports::ReportInstance, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  describe '#start_report' do
    after { travel_back }

    it 'sets state to Started and initializes started_at' do
      travel_to Time.zone.parse('2025-01-01 12:00:00') do
        report = described_class.create!(
          report_name: 'Test Report',
          state: 'Queued',
          question_names: ['test']
        )

        report.start_report

        expect(report.state).to eq('Started')
        expect(report.started_at).to eq(Time.current)
      end
    end

    it 'does not overwrite existing started_at' do
      travel_to Time.zone.parse('2025-01-01 12:00:00') do
        original_start = 1.hour.ago
        report = described_class.create!(
          report_name: 'Test Report',
          state: 'Started',
          started_at: original_start,
          question_names: ['test']
        )

        report.start_report

        expect(report.started_at).to eq(original_start)
      end
    end
  end

  describe '#track_progress' do
    after { travel_back }

    it 'creates and completes a checkpoint' do
      travel_to Time.zone.parse('2025-01-01 12:00:00') do
        report = described_class.create!(
          report_name: 'Test Report',
          state: 'Started',
          started_at: 1.hour.ago,
          question_names: ['test']
        )

        report.track_progress('Q1') do
          travel 5.minutes
        end

        report.reload
        checkpoint = report.checkpoints.last
        expect(checkpoint['name']).to eq('Q1')
        expect(checkpoint['started_at']).to eq(Time.zone.parse('2025-01-01 12:00:00').iso8601)
        expect(checkpoint['completed_at']).to eq(Time.zone.parse('2025-01-01 12:05:00').iso8601)
      end
    end

    it 'handles nested checkpoints' do
      travel_to Time.zone.parse('2025-01-01 12:00:00') do
        report = described_class.create!(
          report_name: 'Test Report',
          state: 'Started',
          started_at: 1.hour.ago,
          question_names: ['test']
        )

        # Outer checkpoint
        report.track_progress('Outer') do
          travel 1.minutes
          # Inner checkpoint
          report.track_progress('Inner') do
            travel 30.minutes
          end
          travel 2.minutes
        end

        report.reload
        expect(report.checkpoints.size).to eq(2)
        expect(report.checkpoints.map { |cp| cp['name'] }).to contain_exactly('Outer', 'Inner')
        expect(report.checkpoints.all? { |cp| cp['completed_at'].present? }).to be true
      end
    end

    it 'completes checkpoint even if block raises error' do
      report = described_class.create!(
        report_name: 'Test Report',
        state: 'Started',
        question_names: ['test']
      )

      expect {
        report.track_progress('Faulty') { raise 'Boom' }
      }.to raise_error('Boom')

      report.reload
      expect(report.checkpoints.last['name']).to eq('Faulty')
      expect(report.checkpoints.last['completed_at']).to be_present
    end
  end

  describe '#total_duration_in_words' do
    after { travel_back }

    it 'calculates duration from multiple checkpoints' do
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
          question_names: ['test']
        )

        # Total: 10 + 15 + 20 = 45 minutes
        expect(report.total_duration_in_words).to eq('about 1 hour')
      end
    end

    it 'calculates duration with nested/overlapping checkpoints' do
      travel_to Time.zone.parse('2025-01-01 12:00:00') do
        # Setup checkpoints that simulate the nested structure directly
        start_t = Time.current
        report = described_class.create!(
          report_name: 'Test Report',
          state: 'Started',
          started_at: start_t,
          checkpoints: [
            # Outer: 0 to 33 mins
            { 'name' => 'Outer', 'started_at' => start_t.iso8601, 'completed_at' => (start_t + 33.minutes).iso8601 },
            # Inner: 1 to 31 mins (contained within Outer)
            { 'name' => 'Inner', 'started_at' => (start_t + 1.minute).iso8601, 'completed_at' => (start_t + 31.minutes).iso8601 }
          ],
          question_names: ['test']
        )

        # Total duration should be just the outer duration (33 minutes), not 33 + 30
        expect(report.total_duration_in_words).to eq('33 minutes')
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
          question_names: ['test']
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
          question_names: ['test']
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
        question_names: ['test']
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
          question_names: ['test']
        )

        expect(report.total_duration_in_words).to eq('less than a minute')
      end
    end
  end
end
