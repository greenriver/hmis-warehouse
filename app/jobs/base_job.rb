class BaseJob < ActiveJob::Base
  STARTING_PATH = File.realpath(FileUtils.pwd)

  before_perform do |job|
    if STARTING_PATH != expected_path
      Rails.logger.info "Started dir is `#{STARTING_PATH}`"
      Rails.logger.info "Current dir is `#{expected_path}`"
      Rails.logger.info "Exiting in order to let systemd restart me in the correct directory."

      unlock_job!(job)

      # Exit, ignoring signal handlers which would prevent the process from dieing
      exit!(0)
    end
  end

  private

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
