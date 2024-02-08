###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
#
# This utility class is used by delayed job workoff rake tasks and allows those
# to exit when a job completes and the worker is not on the latest task
# definition (i.e. the latest code)
class WorkerStatus
  include NotifierConfig

  attr_accessor :job

  def initialize(job)
    self.job = job
  end

  def conditional_exit!
    return unless i_am_a_workoff_worker

    Rails.logger.info "This task's task definition version: #{my_version}"
    Rails.logger.info "The latest task definition version: #{latest_version}"

    return if my_version == -1
    return if latest_version == -1
    return unless my_version < latest_version
    return unless latest_deployment_is_at_least_partially_finished

    Rails.logger.info 'The most recently attempted deployment is finished'

    unlock_job!

    Rails.logger.warn "Exiting because I am a workoff worker that isn't on the latest version"

    # Letting the logs sync, otherwise we lose the last few log lines
    sleep(10)

    exit!(0)
  end

  private

  def unlock_job!
    job_id =
      if job.respond_to? :job_id
        job.job_id
      else
        job.id
      end

    a_t = Delayed::Job.arel_table
    job_object = Delayed::Job.where(a_t[:handler].matches("%job_id: #{job_id}%").or(a_t[:id].eq(job_id))).first
    return unless job_object

    msg = "Marking delayed job as unlocked: #{job_object.locked_by}"
    notify_on_restart(msg)

    job_object.update(locked_by: nil, locked_at: nil)
  end

  def latest_deployment_is_at_least_partially_finished
    return true if Rails.env.development? || Rails.env.test?

    # Couldn't get Curl.get to work
    response = `curl -k https://#{ENV['FQDN']}/system_status/details`
    result = JSON.parse(response)
    result['environment_deployment_id'] == Rails.cache.read('registered-deployment-id')
  rescue JSON::ParserError => e
    Rails.logger.error e.message
    # Worst case is that we exit and have another workoff worker using the
    # old task definition.
    true
  end

  def i_am_a_workoff_worker
    Rails.logger.info "ARGV: #{$ARGV}"
    $ARGV.grep(/workoff/).present? || task_metadata['Family'].match?(/workoff/)
  end

  def latest_version
    return @latest_version unless @latest_version.nil?

    unversioned_task_definition = task_metadata['Family']

    Rails.logger.debug "Unversioned task definition: #{unversioned_task_definition}"

    # We get the latest one if you request without the version at the end
    result = client.describe_task_definition(task_definition: unversioned_task_definition)

    @latest_version = result.task_definition[:task_definition_arn].split(':').last.to_i
  rescue Aws::ECS::Errors::ClientException, Aws::Errors::InvalidProcessCredentialsPayload => e
    Rails.logger.error e.message
    Rails.logger.error 'Unable to determine if we should exit this workoff worker'
    -1
  end

  def my_version
    task_metadata['Revision'].to_i
  end

  # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-metadata-endpoint-v4.html
  def task_metadata
    return @task_metadata unless @task_metadata.nil?

    return default_metadata if ENV['ECS_CONTAINER_METADATA_URI_V4'].blank?

    json = `curl #{ENV['ECS_CONTAINER_METADATA_URI_V4']}/task`
    @task_metadata = JSON.parse(json)
  rescue StandardError => e
    Rails.logger.error e.message
    default_metadata
  end

  def default_metadata
    return JSON.parse(ENV['DEFAULT_METADATA']) if ENV['DEFAULT_METADATA'].present?

    {
      'Family' => 'unknown',
      'Revision' => '-1',
    }
  end

  def client
    @client ||= Aws::ECS::Client.new
  end

  def notify_on_restart(msg)
    Rails.logger.info msg
    return unless File.exist?('config/exception_notifier.yml')

    setup_notifier('DelayedJobRestarter')
    @notifier.ping(msg) if @send_notifications
  end
end
