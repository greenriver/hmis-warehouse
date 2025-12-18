###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base
  class JobCancelled < StandardError; end
  discard_on JobCancelled

  before_perform :handle_cancellation!

  protected

  def handle_cancellation!
    return unless provider_job_id.present?

    # We can't access the job record directly from the instance easily without
    # looking it up.
    job = Delayed::Job.find_by(id: provider_job_id)
    job&.handle_cancellation!
  end
end
