class CheckJobQueueJob < BaseJob

  def perform
    if hung_job.exists?
      notify_of_hung_jobs
    end
  end

  def notify_of_hung_jobs
    if File.exists?('config/exception_notifier.yml')
      setup_notifier('DelayedJobQueue')
      msg = "One or more jobs have been queued for more than 24 hours"
      @notifier.ping(msg) if @send_notifications
    end
  end

  def hung_job
    Delayed::Job.where(Delayed::Job.arel_table[:created_at].lt(24.hours.ago))
  end
end