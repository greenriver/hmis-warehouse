###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class BaseJob < ActiveJob::Base
  STARTING_PATH = File.realpath(FileUtils.pwd)
  include NotifierConfig

  # When called through Active::Job, uses this hook
  before_perform do |job|
    if STARTING_PATH != expected_path || !File.exist?('config/exception_notifier.yml')

      msg = "Started dir is `#{STARTING_PATH}`\nCurrent dir is `#{expected_path}`\nExiting in order to let systemd restart me in the correct directory."
      notify_on_restart(msg)
      unlock_job!(job.job_id) if job.respond_to? :job_id

      # Exit, ignoring signal handlers which would prevent the process from dying
      exit!(0)
    end
  end
  # when queued with perform_later (active job, this gets used)
  # This works in both situations
  rescue_from Exception do |e|
    notify_on_exception(e)
  end

  # When called through Delayed::Job, uses this hook
  def before(job)
    return unless STARTING_PATH != expected_path || ! File.exist?('config/exception_notifier.yml')

    job = self unless job.respond_to? :locked_by

    msg = "Started dir is `#{STARTING_PATH}`\nCurrent dir is `#{expected_path}`\nExiting in order to let systemd restart me in the correct directory."
    notify_on_restart(msg)
    unlock_job!(job.id)

    # Exit, ignoring signal handlers which would prevent the process from dying
    exit!(0)
  end

  # when queued with Delayed::Job.enqueue TestJob.new (this gets used)
  # This will send two notifications for each error, probably
  def error(_job, exception)
    notify_on_exception(exception)
  end

  private

  def notify_on_restart(msg)
    Rails.logger.info msg
    return unless File.exist?('config/exception_notifier.yml')

    setup_notifier('DelayedJobRestarter')
    @notifier.ping(msg) if @send_notifications
  end

  def notify_on_exception(exception)
    return unless File.exist?('config/exception_notifier.yml')

    setup_notifier('DelayedJobFailure')
    msg = if Rails.env.development?
      "*#{self.class.name}* `FAILED` with the following error: \n ```#{exception.inspect}``` ```#{exception.backtrace.inspect}```"
    else
      "*#{self.class.name}* `FAILED` with the following error: \n ```#{exception.inspect}```"
    end
    @notifier.ping(msg) if @send_notifications
    ExceptionNotifier.notify_exception(exception) if @send_notifications
  end

  def expected_path
    Rails.cache.fetch('deploy-dir') do
      # A default for the first deployment and local development
      # This should be set on deployment.
      Delayed::Worker::Deployment.deployed_to
    end
  end

  def unlock_job!(job_id)
    a_t = Delayed::Job.arel_table
    job_object = Delayed::Job.where(a_t[:handler].matches("%job_id: #{job_id}%").or(a_t[:id].eq(job_id))).first
    return unless job_object

    msg = "Restarting stale delayed job: #{job_object.locked_by}"
    notify_on_restart(msg)

    job_object.update_attributes(locked_by: nil, locked_at: nil)
  end
end
