###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Reporting::Hud
  class RunReportJob < BaseJob
    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)
    WAIT_MINUTES = 4

    def perform(class_name, report_id, email: true)
      raise "Unknown HUD Report class: #{class_name}" unless Rails.application.config.hud_reports[class_name].present?

      # Load the report so we can key the advisory lock off of the specific report
      report = HudReports::ReportInstance.find_by(id: report_id)
      # Occasionally people delete the report before it actually runs
      return unless report.present?

      # advisory lock to check the number of jobs running for this generator so we don't
      # all check at exactly the same time and get the same result
      @generator = class_name.constantize.new(report)
      HudReports::ReportInstance.with_advisory_lock(@generator.class.name, timeout_seconds: 20) do
        # We can't only count the running delayed jobs because we start a DJ every time we check
        # So, we'll check the report class for running reports instead.
        running_reports_count = HudReports::ReportInstance.
          created_recently.
          incomplete.
          started.
          for_report(report.report_name).
          count

        if running_reports_count > 1
          puts "Found #{running_reports_count} running reports, for #{@generator.class.name} (#{report.report_name}), postponing run of #{report_id}"
          requeue_job(class_name)
          return
        end
      end

      puts "Running: #{@generator.class.name} Report ID: #{report_id}"

      capture_failure do
        @generator.prepare_report
        @generator.class.questions.each do |q, klass|
          klass.new(@generator, report).run! if report.build_for_questions.include?(q)
        end
      end

      report_completed = report.complete_report
      NotifyUser.driver_hud_report_finished(@generator).deliver_now if report.user_id && email
      report_completed
    end

    protected def capture_failure
      begin
        yield
      rescue StandardError => e
        # for debugging sql issues in tests, raise immediately since attempting further updates will crash in failed tx
        # and we'd like to get the backtrace from the original exception
        raise if Rails.env.test? && e.is_a?(ActiveRecord::StatementInvalid)

        @report.update!(state: 'Failed') unless @report.failed?
        raise
      end
    end

    private def requeue_job(class_name)
      # Re-queue this report before processing if another report is running for the same class
      # This should help prevent tying up delayed job workers when someone kicks off a dozen of the same report.
      a_t = Delayed::Job.arel_table
      job_object = Delayed::Job.where(a_t[:handler].matches("%job_id: #{job_id}%").or(a_t[:id].eq(job_id))).first
      return unless job_object

      Rails.logger.info("Report: #{class_name} already running...re-queuing job for #{WAIT_MINUTES} minutes from now")
      new_job = job_object.dup
      new_job.update(
        locked_at: nil,
        locked_by: nil,
        run_at: Time.current + WAIT_MINUTES.minutes,
        attempts: 0,
      )
    end
  end
end
