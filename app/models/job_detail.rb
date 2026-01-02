###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# JobDetail is a presenter-like model that extracts and normalizes metadata from
# Delayed::Job records, regardless of whether they were queued via ActiveJob
# or the classic .delay (Delayed Job) syntax.
#
# It manages three distinct concepts to distinguish between the "container" and the "content":
# 1. job: The "Container" - The underlying Delayed::Job database record. It manages queueing
#    state like locked_at and last_error, but knows nothing about business logic.
# 2. executor_class: The "Worker" - The technical Ruby class (e.g., Reporting::Hud::RunReportJob)
#    responsible for the background work. We extract this as a real Ruby Class object so we
#    can query it for capabilities like .interruptible?.
# 3. job_class: The "Specific Item" - The domain-specific class being processed
#    (e.g., HudSpmReport::Fy2026::Generator). While the executor_class might be a generic
#    report runner, the job_class tells the administrator exactly what kind of item is being handled.

require 'memery'
class JobDetail
  include Memery

  attr_reader :job

  # @param job [Delayed::Backend::ActiveRecord::Job] The underlying database record representing the queued job.
  def initialize(job)
    @job = job
  end

  def self.queue_status
    Delayed::Job.where(failed_at: nil).group(:queue).count.transform_keys { |k| k&.humanize }
  end

  # The name of the Ruby class that executes the job (e.g. "Reporting::Hud::RunReportJob").
  # For ActiveJob, this is the Job class. For .delay, this is the Class.method or Instance#method string.
  memoize def job_name
    (job.name || '').split(' ').first
  end

  # User ID extracted from job arguments, or 'unknown'
  memoize def user_id
    return arguments.last['user_id'] if job_name.starts_with?('BackgroundRender::') && arguments.last.is_a?(Hash)
    return arguments.first['user_id'] if arguments.first.is_a?(Hash)
    return hud_report_instance&.user_id if job_name == 'Reporting::Hud::RunReportJob'

    'unknown'
  end

  # Normalizes the extraction of arguments from both ActiveJob (job_data)
  # and plain Delayed Job (PerformableMethod) payloads.
  def arguments
    if payload.respond_to?(:job_data) && payload.job_data.is_a?(Hash)
      payload.job_data.try(:[], 'arguments')
    elsif payload.respond_to?(:args)
      payload.args
    end
  end

  memoize def hud_report_instance
    report_id = arguments.try(:second)
    return nil unless report_id

    HudReports::ReportInstance.find_by(id: report_id)
  end

  def created_at
    hud_report_instance&.created_at
  end

  # Attempts to extract a logical "Record ID" from the arguments to display in the dashboard.
  memoize def report_id
    if arguments.is_a?(Hash)
      arguments['report_id']
    elsif arguments.is_a?(Array)
      if arguments.first.is_a?(String) || arguments.first.is_a?(Numeric)
        arguments.first
      else
        arguments.first.try(:[], 'report_id') || (arguments.last if arguments.last.is_a?(Integer))
      end
    end
  end

  # Returns the deserialized payload object stored in the job's handler.
  def payload
    job.payload_object
  end

  # The technical Ruby Class responsible for executing the background work.
  # This unwraps ActiveJob wrappers or PerformableMethod objects to find the actual
  # class where the business logic resides.
  memoize def executor_class
    if payload.respond_to?(:job_data) && payload.job_data.is_a?(Hash)
      begin
        payload.job_data['job_class'].constantize
      rescue StandardError
        nil
      end
    elsif payload.respond_to?(:object)
      # For .delay calls, payload.object might be a Class, a Module, or an instance.
      # If it's a Module/Class, we return it directly so we can check for singleton methods.
      payload.object.is_a?(Module) ? payload.object : payload.object.class
    else
      payload.class
    end
  end

  # True if executor_class supports cancellation via periodic checks
  def interruptible?
    executor_class.respond_to?(:interruptible?) && executor_class.interruptible?
  end

  # The domain-specific class being processed (e.g. "HudSpmReport::Fy2026::Generator").
  # This provides high-level context for what the job is actually doing, which may
  # be more specific than the executor_class itself.
  memoize def job_class
    return nil unless arguments

    if job_name.starts_with?('BackgroundRender::')
      job_name
    elsif arguments.is_a?(Hash)
      arguments.try(:[], 'report_class')
    else
      return arguments.first.to_s if arguments.first.is_a?(String) || arguments.first.is_a?(Numeric)

      arguments.first.try(:[], 'report_class')
    end
  end
end
