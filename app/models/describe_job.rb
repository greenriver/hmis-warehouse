###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# TODO: Maybe move other items from DelayedJob initializer code into here?
class DescribeJob < OpenStruct
  attr_reader :job
  def initialize(job)
    @job = job
  end

  def self.queue_status
    Delayed::Job.where(failed_at: nil).group(:queue).count.transform_keys { |k| k&.humanize }
  end

  def job_name
    @job_name ||= job.name.split(' ').first
  end

  def user_id
    @user_id ||= begin
      user_id = if job_name.starts_with?('BackgroundRender::')
        arguments.last['user_id']
      elsif arguments.try(:first).is_a?(Hash)
        # This should handle `WarehouseReports::GenericReportJob`
        arguments.first.try(:[], 'user_id')
      elsif job_name == 'Reporting::Hud::RunReportJob'
        hud_report_instance&.user_id
      end

      user_id || 'unknown'
    end
  end

  def arguments
    return payload.job_data.try(:[], 'arguments') if payload.respond_to?(:job_data)

    nil
  end

  # HUD report, pull user from the report
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
    @report_id ||= arguments.first.try(:[], 'report_id')
    @report_id ||= arguments&.last if arguments&.last.is_a?(Integer)
    @report_id
  end

  def payload
    @payload ||= job.payload_object
  end

  def job_class
    return nil unless arguments

    @job_class ||= if job_name.starts_with?('BackgroundRender::')
      job_name
    elsif arguments.is_a?(Hash)
      arguments.try(:[], 'report_class')
    else
      return arguments.first if arguments.first.is_a?(String)

      arguments.first.try(:[], 'report_class')
    end
  end
end
