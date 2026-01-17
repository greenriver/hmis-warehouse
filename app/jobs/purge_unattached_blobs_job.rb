# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Purge unattached Active Storage blobs older than a specified age.
#
# Active Storage creates "unattached" blobs when files are cached for form resubmissions
# (e.g., Health::HealthFile's cached_file attachment). These blobs should be purged after
# they're no longer needed to avoid accumulating orphaned files in storage.
class PurgeUnattachedBlobsJob < BaseJob
  queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

  # @param older_than [ActiveSupport::Duration] Purge blobs created before this duration ago (default: 2 days)
  def perform(older_than: 2.days)
    instrument_as_maintenance_task do |run|
      ActiveStorage::Blob.with_advisory_lock(
        'purge_unattached_blobs_job',
        timeout_seconds: 0,
      ) do
        purged_count = 0
        ActiveStorage::Blob.unattached.where('active_storage_blobs.created_at <= ?', older_than.ago).find_each do |blob|
          blob.purge
          purged_count += 1
        end

        Rails.logger.info "Purged #{purged_count} unattached Active Storage blobs"
        run.complete!
      end
    end
  end
end
