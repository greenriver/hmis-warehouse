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
  end

  def notify_of_hung_jobs
    Rails.logger.tagged('DelayedJobQueue') do
      Rails.logger.info('One or more jobs have been queued for more than 24 hours')
    end
    # TODO: Prometheus metric
  end

  def hung_job
    Delayed::Job.where(Delayed::Job.arel_table[:created_at].lt(24.hours.ago))
  end
end
