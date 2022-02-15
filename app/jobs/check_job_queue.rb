###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# This is not actually a Job -- it is located here since it reasons about them...
class CheckJobQueue
  include NotifierConfig

  def perform
    notify_of_hung_jobs if hung_job.exists?
  rescue Exception => e
    notify_on_exception(e)
  end

  def notify_of_hung_jobs
    return unless File.exist?('config/exception_notifier.yml')

    setup_notifier('DelayedJobQueue')
    msg = 'One or more jobs have been queued for more than 24 hours'
    @notifier.ping(msg) if @send_notifications
  end

  # From BaseJob
  def notify_on_exception(exception)
    return unless File.exist?('config/exception_notifier.yml')

    setup_notifier('DelayedJobQueue')
    msg = "*#{self.class.name}* `FAILED` with the following error: \n ```#{exception.inspect}```"
    @notifier.ping(msg) if @send_notifications
  end

  def hung_job
    Delayed::Job.where(Delayed::Job.arel_table[:created_at].lt(24.hours.ago))
  end
end
