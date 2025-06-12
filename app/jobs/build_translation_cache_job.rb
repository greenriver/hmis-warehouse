# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# warm cache from db translations
class BuildTranslationCacheJob < BaseJob
  queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)
  LOCK_NAME = 'build_translation_cache'

  def perform(...)
    instrument_as_maintenance_task do |run|
      run.complete! if _perform(...)
    end
  end

  def _perform
    did_run = false
    Translation.with_advisory_lock(LOCK_NAME, shared: false, timeout_seconds: 0) do
      translations = Translation.order(:id).pluck(:key, :text)

      translations.in_groups_of(500, false) do |batch|
        values = batch.to_h.transform_keys { |key| Translation.cache_key(key) }
        Rails.cache.write_multi(values)
      end
      did_run = true
    end
    did_run
  end

  def max_attempts
    1
  end
end
