###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# TODO: Maybe move other items from DelayedJob initializer code into here?
class JobDetail
  attr_reader :job
  def initialize(job)
    @job = job
  end

  def self.queue_status
    Delayed::Job.where(failed_at: nil).group(:queue).count.transform_keys { |k| k&.humanize }
  end

  # The name of the Ruby class that executes the job (e.g. "Reporting::Hud::RunReportJob").
  def job_name
    @job_name ||= executor_class&.name || job.name.split(' ').first
  end

  def user_id
    @user_id ||= begin
      user_id = if job_name.starts_with?('BackgroundRender::')
        arguments.last['user_id']
      elsif arguments.try(:first).is_a?(Hash)
        # This should handle `WarehouseReports::GenericReportJob`
        arguments.first.try(:[], 'user_id')
      elsif job_name == 'Reporting::Hud::RunReportJob'
        # HUD report, pull user from the report
        hud_report_instance&.user_id
      end

      user_id || 'unknown'
    end
  end

  def arguments
    return payload.job_data.try(:[], 'arguments') if payload.respond_to?(:job_data)

    nil
  end

  def hud_report_instance
    report_id = arguments.try(:second)
    return nil unless report_id

    @hud_report_instance ||= HudReports::ReportInstance.find_by(id: report_id)
  end

  def created_at
    hud_report_instance&.created_at
  end

  def report_id
    @report_id ||= arguments.try(:[], 'report_id') if arguments.is_a?(Hash)
    @report_id ||= arguments.first if arguments.first.is_a?(String) || arguments.first.is_a?(Numeric)
    @report_id ||= arguments.first.try(:[], 'report_id')
    @report_id ||= arguments&.last if arguments&.last.is_a?(Integer)
    @report_id
  end

  def payload
    @payload ||= job.payload_object
  end

  # The technical Class that executes the background work.
  # Extracts the class from ActiveJob wrappers if present.
  def executor_class
    @executor_class ||= begin
      if payload.respond_to?(:job_data)
        payload.job_data['job_class'].constantize rescue nil
      else
        payload.class
      end
    end
  end

  def interruptible?
    executor_class.respond_to?(:interruptible?) && executor_class.interruptible?
  end

  # The domain-specific class being processed (e.g. "HudSpmReport::Fy2026::Generator").
  # This is displayed as "Job Item" in the admin dashboard.
  def job_class
    return nil unless arguments

    @job_class ||= if job_name.starts_with?('BackgroundRender::')
      job_name
    elsif arguments.is_a?(Hash)
      arguments.try(:[], 'report_class')
    else
      return arguments.first.to_s if arguments.first.is_a?(String) || arguments.first.is_a?(Numeric)

      arguments.first.try(:[], 'report_class')
    end
  end
end
