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
          question_names: ['test'],
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
          question_names: ['test'],
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
          question_names: ['test'],
        )

        report.track_progress('Q1') do
          travel 5.minutes
        end

        checkpoint = report.checkpoints.last
        expect(checkpoint.name).to eq('Q1')
        expect(checkpoint.started_at).to eq(Time.zone.parse('2025-01-01 12:00:00'))
        expect(checkpoint.completed_at).to eq(Time.zone.parse('2025-01-01 12:05:00'))
        expect(checkpoint.status).to eq('success')
      end
    end

    it 'completes checkpoint even if block raises error' do
      report = described_class.create!(
        report_name: 'Test Report',
        state: 'Started',
        question_names: ['test'],
      )

      expect do
        report.track_progress('Faulty') { raise 'Boom' }
      end.to raise_error('Boom')

      checkpoint = report.checkpoints.last
      expect(checkpoint.name).to eq('Faulty')
      expect(checkpoint.completed_at).to be_present
      expect(checkpoint.status).to eq('error')
    end
  end

  describe '#total_duration_in_words' do
    after { travel_back }
    let(:base_time) { Time.current }
    let(:report) do
      described_class.create!(
        report_name: 'Test Report',
        state: 'Completed',
        started_at: base_time,
        completed_at: base_time,
        question_names: ['test'],
      )
    end

    it 'calculates duration from multiple checkpoints' do
      travel_to Time.zone.parse('2025-01-01 12:00:00') do
        base_time = Time.current

        # Create checkpoints
        report.checkpoints.create!(name: 'Prep', started_at: base_time, completed_at: base_time + 10.minutes, status: 'success')
        report.checkpoints.create!(name: 'Q1', started_at: base_time + 10.minutes, completed_at: base_time + 25.minutes, status: 'success')
        report.checkpoints.create!(name: 'Q2', started_at: base_time + 25.minutes, completed_at: base_time + 45.minutes, status: 'success')

        # Total: 10 + 15 + 20 = 45 minutes
        expect(report.total_duration_in_words).to eq('about 1 hour')
      end
    end

    it 'excludes crashed checkpoints from duration' do
      travel_to Time.zone.parse('2025-01-01 12:00:00') do
        # Create checkpoints
        report.checkpoints.create!(name: 'Prep', started_at: base_time, completed_at: base_time + 10.minutes, status: 'success')
        report.checkpoints.create!(name: 'Q1', started_at: base_time + 10.minutes, completed_at: nil, status: 'running') # Crashed - no completed_at

        # Only counts completed checkpoint: 10 minutes
        expect(report.total_duration_in_words).to eq('10 minutes')
      end
    end
  end
end
