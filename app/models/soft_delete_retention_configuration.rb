# frozen_string_literal: true

###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Shared retention configuration for soft-delete purge jobs.
# Values are managed via AppConfigProperty and editable in the admin UI.
#
# @see PurgeSoftDeletedRecordsJob
# @see PurgeSoftDeletedClientFilesJob
class SoftDeleteRetentionConfiguration
  DEFAULT_RETENTION_PERIOD_DAYS = 365
  DEFAULT_MAX_DELETED_PER_RUN = 10_000_000

  # Whether purging is enabled. Defaults to true in staging, false otherwise.
  def enabled?
    value = value_for(:enabled)
    return ActiveModel::Type::Boolean.new.cast(value) if value.present?

    Rails.env.staging?
  end

  # Number of days to retain soft-deleted records before purging.
  def retention_period_days
    value_for(:retention_period_days)&.to_i.presence || DEFAULT_RETENTION_PERIOD_DAYS
  end

  # Convenience timestamp: records deleted before this time are eligible for purging.
  def retain_at
    retention_period_days.days.ago
  end

  # Safety cap on records deleted in a single job run.
  def max_deleted_per_run
    value_for(:max_deleted_per_run)&.to_i || DEFAULT_MAX_DELETED_PER_RUN
  end

  protected

  PROPERTIES = [
    :enabled,
    :retention_period_days,
    :max_deleted_per_run,
  ].freeze

  def values
    @values ||= AppConfigProperty.
      where(key: PROPERTIES.map { |attr| key_for(attr) }).
      pluck(:key, :value).
      to_h
  end

  def value_for(attr)
    values[key_for(attr)].presence
  end

  def key_for(attr)
    "purge_soft_deleted_records/#{attr}"
  end
end
