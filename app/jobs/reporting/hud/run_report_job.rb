###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Reporting::Hud
  class RunReportJob < BaseJob
    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)
    WAIT_MINUTES = 10

    def perform(class_name, report_id, email: true)
      lock_obtained = HudReports::ReportInstance.with_advisory_lock(advisory_lock_name(class_name), timeout_seconds: 0) do
        raise "Unknown HUD Report class: #{class_name}" unless Rails.application.config.hud_reports[class_name].present?

        report = HudReports::ReportInstance.find_by(id: report_id)
        # Occassionally people delete the report before it actually runs
        return unless report.present?

        report.start_report
        @generator = class_name.constantize.new(report)
        @generator.class.questions.each do |q, klass|
          next unless report.build_for_questions.include?(q)

          klass.new(@generator, report).run!
        end

        report_completed = report.complete_report
        NotifyUser.driver_hud_report_finished(@generator).deliver_now if report.user_id && email
        report_completed
      end
      return if lock_obtained

      requeue_job(class_name)
    end

    private def advisory_lock_name(class_name)
      "hud_report_#{class_name}"
    end

    private def requeue_job(class_name)
      # Re-queue this repot before processing if another report is running for the same class
      # This should help prevent tying up delayed job workers that are really just waiting
      # for the previous import to complete
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
