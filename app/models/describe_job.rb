###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class DescribeJob < OpenStruct
  attr_reader :job
  def initialize(job)
    @job = job
  end

  def job_name
    @job_name ||= job.name.split(' ').first
  end

  def user_id
    @user_id ||= begin
      user_id = if payload.respond_to?(:job_data) && payload.job_data.try(:[], 'arguments').try(:first).is_a?(Hash)
        # This should handle `WarehouseReports::GenericReportJob`
        payload.job_data['arguments'].first.try(:[], 'user_id')
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

  def payload
    @payload ||= job.payload_object
  end

  def job_class
    return nil unless arguments

    if arguments.is_a?(Hash)
      arguments.try(:[], 'report_class')
    else
      return arguments.first if arguments.first.is_a?(String)

      arguments.first.try(:[], 'report_class')
    end
  end
end
