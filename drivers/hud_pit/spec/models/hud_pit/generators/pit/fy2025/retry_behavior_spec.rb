###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative './hud_pit_context'

RSpec.describe 'HUD PIT FY2025 retry behavior', type: :model do
  include_context 'HUD pit context'

  let(:generator_class) { HudPit::Generators::Pit::Fy2025::Generator }

  def create_and_queue_report(project_ids)
    filter = Filters::HudFilterBase.new(**filter_params)
    filter.project_ids = project_ids

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

  let(:project) { create_project(project_type: 0) }
  let(:client) { create_client_with_warehouse_link }
  let(:enrollment) do
    create_enrollment(
      client: client,
      project: project,
      entry_date: pit_date - 1.day,
      exit_date: nil,
    )
  end

  before do
    enrollment
    GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)
  end

  describe 're-processing a PIT report' do
    it 'blocks retry attempts if report was previously started' do
      report = create_and_queue_report([project.id])

      # Simulate a failure by setting started_at
      report.start_report

      # Retry should fail with explicit error
      expect do
        run_job_for(report)
      end.to raise_error(StandardError, /Cannot retry.*does not support idempotent retry/)
    end

    it 'allows fresh runs to proceed normally' do
      report = create_and_queue_report([project.id])

      # Fresh run should succeed
      expect do
        run_job_for(report)
      end.not_to raise_error

      expect(report).to be_completed
    end
  end
end
