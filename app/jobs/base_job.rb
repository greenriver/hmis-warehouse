
class BaseJob < ActiveJob::Base
  STARTING_PATH = File.realpath(FileUtils.pwd)
  include NotifierConfig

  before_perform do |job|
    if STARTING_PATH != expected_path
      Rails.logger.info "Started dir is `#{STARTING_PATH}`"
      Rails.logger.info "Current dir is `#{expected_path}`"
      Rails.logger.info "Exiting in order to let systemd restart me in the correct directory."

      unlock_job!(job)

      # Exit, ignoring signal handlers which would prevent the process from dying
      exit!(0)
    end
  end

  # when queued with perform_later (active job, this gets used)
  # This works in both situations
  rescue_from Exception do |e|
    notify_on_exception(e)
  end

  # when queued with Delayed::Job.enqueue TestJob.new (this gets used)
  # def error(job, e)
  #   notify_on_exception(e)
  # end

  private

  def notify_on_exception exception
    setup_notifier('DelayedJobFailure')
    msg = "*#{self.class.name}* `FAILED` with the following error: \n ```#{exception.inspect}```"
    @notifier.ping(msg) if @send_notifications
  end

  def expected_path
    Rails.cache.fetch('deploy-dir') do
      # A default for the first deployment and local development
      # This should be set on deployment.
      File.realpath(FileUtils.pwd)
    end
  end

  def unlock_job!(job)
    a_t = Delayed::Job.arel_table
    job_object = Delayed::Job.where(a_t[:handler].matches("%job_id: #{job.job_id}%")).first

    job_object.update_attributes(locked_by: nil, locked_at: nil)
  end
end
