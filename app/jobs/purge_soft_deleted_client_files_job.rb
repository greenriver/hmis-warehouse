# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Purge soft-deleted ClientFile records whose retention window has expired.
# For each record: purges the ActiveStorage blob from S3, then hard-deletes
# the database record (including taggings).
#
# ClientFile uses `soft_delete` (sets deleted_at without firing destroy
# callbacks) to preserve taggings for restorability. This job is the
# counterpart that cleans up once the restore window has passed.
class PurgeSoftDeletedClientFilesJob < BaseJob
  queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

  # @param retain_at [DateTime] Records deleted before this time will be purged
  # @param batch_size [Integer] Number of records to process per batch
  def perform(retain_at: nil, max_deleted: nil, batch_size: 1_000)
    config = SoftDeleteRetentionConfiguration.new
    return 0 unless config.enabled?

    retain_at ||= config.retain_at
    max_deleted ||= config.max_deleted_per_run

    total = 0

    with_lock do
      scope = GrdaWarehouse::ClientFile.only_deleted.where(
        GrdaWarehouse::ClientFile.arel_table[:deleted_at].lt(retain_at),
      ).with_attached_client_file

      scope.find_each(batch_size: batch_size) do |file|
        file.client_file.purge if file.client_file.attached?
        file.really_destroy!
        total += 1
        break if total >= max_deleted
      end
    end

    Rails.logger.info "PurgeSoftDeletedClientFilesJob: purged #{total} records"
    total
  end

  private

  def with_lock(&block)
    GrdaWarehouseBase.with_advisory_lock('PurgeSoftDeletedClientFilesJob', timeout_seconds: 0, &block)
  end
end
