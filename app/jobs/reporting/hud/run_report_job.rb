# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Reporting::Hud
  class RunReportJob < BaseJob
    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)
    WAIT_MINUTES = 4
    ORIGINAL_FAILURE_SEPARATOR = "\nOriginal failure:\n"

    def self.interruptible?
      true
    end

    class NonIdempotentRetryError < StandardError; end

    def perform(class_name, report_id, email: true)
      raise "Unknown HUD Report class: #{class_name}" unless Rails.application.config.hud_reports[class_name].present?

      # Load the report so we can key the advisory lock off of the specific report
      report = HudReports::ReportInstance.find_by(id: report_id)
      # Occasionally people delete the report before it actually runs
      return unless report.present?

      report.active_job = self

      # advisory lock to check the number of jobs running for this generator so we don't
      # all check at exactly the same time and get the same result
      @generator = class_name.constantize.new(report)

      # this report was called directly as opposed to being called through an automated process (e.g. to back a different report)
      # so we'll make sure there isn't another similar report running before we start
      if report.manual
        requeued = check_and_requeue_for_running(report, @generator.class.name)
        # a similar report is already running, this report has been adding back to the queue so it will be tried again in a bit
        return if requeued
      end

      # puts "Running: #{@generator.class.name} Report ID: #{report_id}"
      run_report(report, @generator, email: email)
    end

    # Check if a similar report is already running and requeue this report if it is
    #
    # @param report [HudReports::ReportInstance] the report to check
    # @param generator_class_name [String] the class name of the generator
    # @return [Boolean] true if the report was requeued, false otherwise
    protected def check_and_requeue_for_running(report, generator_class_name)
      HudReports::ReportInstance.with_advisory_lock(generator_class_name, timeout_seconds: 20) do
        # We can't only count the running delayed jobs because we start a DJ every time we check
        # So, we'll check the report class for running reports instead.
        running_reports_count = HudReports::ReportInstance.
          created_recently.
          incomplete.
          started.
          for_report(report.report_name).
          count

        if running_reports_count > 1
          puts "Found #{running_reports_count} running reports, for #{generator_class_name} (#{report.report_name}), postponing run of #{report.id}"
          requeue_job(generator_class_name)
          return true
        end
      end
      false
    end

    protected def run_report(report, generator, email:)
      capture_failure(report) do
        # Fail-fast if attempting to retry a report that doesn't support idempotent retry
        # Check started_at to catch all retry scenarios (completed questions, partial runs, mid-question failures)
        if report.started_at.present? && !generator.class.supports_idempotent_retry?
          message = non_idempotent_retry_message(report, generator.class)
          report.update!(error_details: message)
          Rails.logger.warn("[HUD Reports] #{message}")
          raise NonIdempotentRetryError, message
        end

        report.track_progress('Preparation') do
          generator.prepare_report
        end
        completed_questions = report.completed_questions

        generator.class.questions.each do |q, klass|
          next if completed_questions.include?(q)

          next unless report.build_for_questions.include?(q)

          report.track_progress(q) do
            klass.new(generator, report).run!
          end
        end
      end

      report_completed = report.complete_report
      NotifyUser.driver_hud_report_finished(generator).deliver_now if report.user_id && email
      report_completed
    end

    protected def capture_failure(report)
      yield
    rescue StandardError => e
      # for debugging sql issues in tests, raise immediately since attempting further updates will crash in failed tx
      # and we'd like to get the backtrace from the original exception
      raise if Rails.env.test? && e.is_a?(ActiveRecord::StatementInvalid)

      report.update!(state: 'Failed') unless report.failed?
      raise
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

    private def non_idempotent_retry_message(report, generator_class)
      base = "Cannot retry #{generator_class.name}: this report does not support idempotent retry. " \
             "Report was previously started at #{report.started_at}. Please create a new report instead."

      previous_failure = original_failure_message(report).presence
      previous_failure ? "#{base}#{ORIGINAL_FAILURE_SEPARATOR}#{previous_failure}" : base
    end

    private def original_failure_message(report)
      last_error = report.related_job&.last_error.to_s.strip
      return nil if last_error.blank?

      last_error.include?(ORIGINAL_FAILURE_SEPARATOR) ? last_error.split(ORIGINAL_FAILURE_SEPARATOR, 2).last : last_error
    end
  end
end
