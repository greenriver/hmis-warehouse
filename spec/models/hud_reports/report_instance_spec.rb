###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HudReports::ReportInstance, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  describe '#report_definition_url' do
    let(:urls) { GrdaWarehouse::WarehouseReports::ReportDefinition::HUD_URLS }

    def url_for(generator) = described_class.new(report_name: generator.title).report_definition_url

    it 'maps a run to the definition url of the generator that produced it' do
      expect(url_for(HudApr::Generators::Apr::Fy2026::Generator)).to eq(urls[:aprs])
      expect(url_for(HudApr::Generators::Caper::Fy2026::Generator)).to eq(urls[:capers])
      expect(url_for(HopwaCaper::Generators::Fy2024::Generator)).to eq(urls[:hopwa_capers])
      expect(url_for(HopwaCaper::Generators::Fy2026::Generator)).to eq(urls[:hopwa_capers])
      expect(url_for(HudLsa::Generators::Fy2027::Lsa)).to eq(urls[:lsas])
    end

    it 'maps retired generators to their parent report without making them runnable' do
      expect(url_for(HudLsa::Generators::Fy2024::Lsa)).to eq(urls[:lsas])
      expect(url_for(HudDataQualityReport::Generators::Fy2022::Generator)).to eq(urls[:dqs])
      expect(Rails.application.config.hud_reports.keys).not_to include('HudLsa::Generators::Fy2024::Lsa', 'HudDataQualityReport::Generators::Fy2022::Generator')
    end

    it 'returns nil for a report name no generator produces' do
      expect(described_class.new(report_name: 'Not a HUD report').report_definition_url).to be_nil
    end

    it 'gives every registered and aliased generator a distinct title' do
      names = Rails.application.config.hud_reports.keys + Rails.application.config.hud_report_definition_aliases.keys
      titles = names.map { |name| name.constantize.title }

      expect(titles).to eq(titles.uniq)
    end

    it 'maps every generator a HUD controller serves' do
      Rails.application.eager_load!
      generators = HudReports::BaseController.descendants.
        select { |controller| controller.private_method_defined?(:possible_generator_classes) || controller.method_defined?(:possible_generator_classes) }.
        flat_map { |controller| controller.new.send(:possible_generator_classes).values }.
        uniq

      expect(generators).to include(HudLsa::Generators::Fy2022::Lsa, HudDataQualityReport::Generators::Fy2020::Generator, HudPathReport::Generators::Fy2026::Generator)
      expect(generators.reject { |generator| described_class.report_definition_url_for(generator.title) }).to eq([])
    end
  end

  describe '.viewable_by' do
    let(:user) { create(:acl_user) }
    let!(:own_report) { described_class.create!(report_name: 'Test Report', user_id: user.id, question_names: ['test']) }
    let!(:other_report) { described_class.create!(report_name: 'Test Report', user_id: create(:acl_user).id, question_names: ['test']) }

    it 'limits a user without can_view_all_hud_reports to their own reports' do
      setup_access_control(user, create(:role, can_view_assigned_reports: true), create(:collection))

      expect(described_class.viewable_by(user)).to contain_exactly(own_report)
    end

    it 'includes every user\'s reports for a user with can_view_all_hud_reports' do
      setup_access_control(user, create(:role, can_view_all_hud_reports: true), create(:collection))

      expect(described_class.viewable_by(user)).to contain_exactly(own_report, other_report)
    end
  end

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

    it 'resumes (skips block) if a successful checkpoint already exists' do
      report = described_class.create!(
        report_name: 'Test Report',
        state: 'Started',
        question_names: ['test'],
      )

      # Create an existing successful checkpoint
      existing_checkpoint = report.checkpoints.create!(
        name: 'Resumable Step',
        started_at: 1.hour.ago,
        completed_at: 50.minutes.ago,
        status: 'success',
      )

      executed = false
      returned_checkpoint = report.track_progress('Resumable Step') do
        executed = true
      end

      expect(executed).to be false
      expect(returned_checkpoint).to eq(existing_checkpoint)
      # Ensure no new checkpoint was created
      expect(report.checkpoints.count).to eq(1)
    end

    it 'does NOT resume if previous checkpoint failed' do
      report = described_class.create!(
        report_name: 'Test Report',
        state: 'Started',
        question_names: ['test'],
      )

      # Create an existing failed checkpoint
      report.checkpoints.create!(
        name: 'Failed Step',
        started_at: 1.hour.ago,
        completed_at: 50.minutes.ago,
        status: 'error',
      )

      executed = false
      report.track_progress('Failed Step') do
        executed = true
      end

      expect(executed).to be true
      # Should have the failed one and the new success one
      expect(report.checkpoints.count).to eq(2)
      expect(report.checkpoints.last.status).to eq('success')
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

  describe '#current_status' do
    it 'returns Archived when purged (matches Reporting::Status / SimpleReports history)' do
      report = described_class.create!(
        report_name: 'Test Report',
        state: 'Completed',
        started_at: 1.hour.ago,
        completed_at: Time.current,
        question_names: ['test'],
        archival_metadata: { 'purged_at' => Time.current.iso8601 },
      )

      expect(report.current_status(include_error_details: false)).to eq('Archived')
    end
  end
end
