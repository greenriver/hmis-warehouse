###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

silence_warnings do
  OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE if Rails.env.development?
end

# Safety net: if a blob's backing object is gone from S3 by the time the analyze
# job runs (e.g. soft-deleted record whose purge already fired, or a failed S3
# upload), discard the job instead of retrying.
Rails.application.config.after_initialize do
  ActiveStorage::AnalyzeJob.discard_on(ActiveStorage::FileNotFoundError) do |_job, error|
    Sentry.capture_exception(error) if Sentry.initialized?
  end
end
