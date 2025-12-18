###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base
  # Custom error to signal that a job should be stopped because cancellation was requested.
  class JobCancelled < StandardError; end

  # discard_on is a standard Active Job feature
  # When JobCancelled is raised, Active Job catches it and prevents any retries.
  discard_on JobCancelled

  # Check for cancellation before the job starts performing.
  before_perform :handle_cancellation!

  protected

  def handle_cancellation!
    return unless self.class.queue_adapter_name == 'delayed_job'
    return unless provider_job_id.present?

    # provider_job_id is the ID of the Delayed::Job record in the database.
    # We look up the record to check its specific cancellation state.
    job = Delayed::Job.find_by(id: provider_job_id)

    # This calls the handle_cancellation! method defined in the Delayed::Job monkey patch
    # (see config/initializers/delayed_job.rb), which raises JobCancelled if
    # cancellation_requested_at is set.
    job&.handle_cancellation!
  end
end
