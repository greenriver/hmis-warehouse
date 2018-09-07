class BaseJob < ActiveJob::Base

  before_perform do |job|
    if ! should_perform?
      a_t = Delayed::Job.arel_table
      original_job = Delayed::Job.where(a_t[:handler].matches("%job_id: #{job.job_id}%")).first
      original_job_pid = get_pid_from_job(original_job)
      pid = Process.pid
      if original_job_pid && pid == original_job_pid
        Rails.logger.fatal "RESTARTING DELAYED JOB #{pid}"

        setup_new_job(original_job)
        original_job.destroy
        exec("kill #{pid}")
      end
    end
  end

  def should_perform?
    return true unless ENV['GIT_REVISION'].present?
    return true unless File.exists?(File.join(ENV['CURRENT_PATH'], 'REVISION'))
    current_revision = File.read(File.join(ENV['CURRENT_PATH'], 'REVISION'))&.strip
    return current_revision == ENV['GIT_REVISION']
  end

  def setup_new_job old_job
    new_job = old_job.dup
    new_job.assign_attributes(
      id: nil,
      attempts: 0,
      locked_at: nil,
      locked_by: nil,
      last_error: nil,
      failed_at: nil,
    )
    new_job.save!
  end

  # NOTE: Do we need to check our hostname?
  def get_pid_from_job job
    /pid:(\d+)/.match(job.locked_by).try(:[], 1)&.to_i
  end

end
