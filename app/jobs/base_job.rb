###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class BaseJob < ApplicationJob
  STARTING_PATH = File.realpath(FileUtils.pwd)
  include NotifierConfig

  if ENV['ECS'] != 'true'
    # When called through Active::Job, uses this hook
    before_perform do |job|
      unless running_in_correct_path?

        msg = "Started dir is `#{STARTING_PATH}`\nCurrent dir is `#{expected_path}`\nExiting in order to let systemd restart me in the correct directory. Active::Job"
        notify_on_restart(msg)

        unlock_job!(job.job_id) if job.respond_to? :job_id

        # Exit, ignoring signal handlers which would prevent the process from dying
        exit!(0)
      end
    end
  end

  if ENV['ECS'] != 'true'
    # When called through Delayed::Job, uses this hook
    def before(job)
      return if running_in_correct_path?

      job = self unless job.respond_to? :locked_by

      msg = "Started dir is `#{STARTING_PATH}`\nCurrent dir is `#{expected_path}`\nExiting in order to let systemd restart me in the correct directory. Delayed::Job"
      notify_on_restart(msg)

      unlock_job!(job.id)

      # Exit, ignoring signal handlers which would prevent the process from dying
      exit!(0)
    end
  end

  if ENV['ECS'] == 'true'
    # When called through Delayed::Job, uses this hook
    def before(job)
      WorkerStatus.new(job).conditional_exit!
    end

    # When called through Active::Job, uses this hook
    before_perform do |job|
      WorkerStatus.new(job).conditional_exit!
    end
  end

  private

  def running_in_correct_path?
    return true unless File.exist?('config/exception_notifier.yml')

    expected_path == STARTING_PATH
  end

  def notify_on_restart(msg)
    Rails.logger.info msg
    return unless File.exist?('config/exception_notifier.yml')

    setup_notifier('DelayedJobRestarter')
    @notifier.ping(msg) if @send_notifications
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

    job_object.update(locked_by: nil, locked_at: nil)
  end
end
