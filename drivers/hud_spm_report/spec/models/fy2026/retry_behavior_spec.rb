###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative './shared_context'

RSpec.describe 'HUD SPM FY2026 retry behavior', type: :model do
  include_context '2026 SPM test setup'

  let(:generator_class) { HudSpmReport::Generators::Fy2026::Generator }

  def create_and_queue_report(project_ids)
    filter = default_filter.dup
    filter.update(project_ids: project_ids)

    report = HudReports::ReportInstance.from_filter(
      filter,
      generator_class.title,
      build_for_questions: generator_class.questions.keys,
    )
    report.manual = true

    generator_class.new(report).queue
    report.reload
  end

  def run_job_for(report)
    Reporting::Hud::RunReportJob.perform_now(generator_class.name, report.id, email: false)
    report.reload
  end

  def measure_one_episode_ids(report)
    HudReports::UniverseMember.
      joins(:report_cell).
      merge(HudReports::ReportCell.where(report_instance_id: report.id)).
      where(universe_membership_type: 'HudSpmReport::Fy2026::Episode').
      distinct.
      pluck(:universe_membership_id)
  end

  describe 're-processing a long-running SPM report' do
    it 'does not double-count or reuse partial data when the same report is retried' do
      project = create_project(project_type: 0)
      client = create_client_with_warehouse_link
      create_enrollment(
        client: client,
        project: project,
        entry_date: default_filter.start,
        exit_date: default_filter.end,
      )

      GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)

      report = create_and_queue_report([project.id])

      run_job_for(report)

      expect(report).to be_completed
      initial_episode_ids = measure_one_episode_ids(report)
      initial_episode_count = initial_episode_ids.count
      initial_return_count = HudSpmReport::Fy2026::Return.where(report_instance_id: report.id).count
      expect(initial_episode_count).to be > 0

      report.update!(state: 'Waiting', completed_at: nil)

      run_job_for(report)

      report.reload
      expect(report).to be_completed

      episodes_after_retry = measure_one_episode_ids(report).count
      returns_after_retry = HudSpmReport::Fy2026::Return.where(report_instance_id: report.id).count

      expect(episodes_after_retry).to eq(initial_episode_count)
      expect(returns_after_retry).to eq(initial_return_count)
    end
  end

  describe 'job cancellation' do
    it 'stops processing when cancellation is requested mid-run' do
      project = create_project(project_type: 0)
      report = create_and_queue_report([project.id])

      # Manually create a matching Delayed::Job record because the test adapter won't.
      # HudReports::ReportInstance#related_job looks for 'RunReportJob' and the report ID in the handler.
      job = Delayed::Job.create!(
        handler: {
          'job_class' => 'Reporting::Hud::RunReportJob',
          'arguments' => [generator_class.name, report.id],
        }.to_yaml,
      )
      expect(report.related_job).to eq(job)

      # We need to trick ApplicationJob into thinking it's running under delayed_job
      # so it doesn't skip check_halt_status!.
      allow(Reporting::Hud::RunReportJob).to receive(:queue_adapter_name).and_return('delayed_job')
      allow_any_instance_of(Reporting::Hud::RunReportJob).to receive(:provider_job_id).and_return(job.id)

      # Mock a point in the process to request cancellation.
      # create_enrollment_set is called early in the report process.
      allow(HudSpmReport::Adapters::ServiceHistoryEnrollmentFilter).to receive(:new).and_wrap_original do |m, *args|
        job.update!(cancellation_requested_at: Time.current)
        m.call(*args)
      end

      # Run the job. It should raise JobCancelled but ActiveJob should discard it.
      expect { run_job_for(report) }.not_to raise_error

      report.reload
      expect(report).not_to be_completed
    end
  end
end
