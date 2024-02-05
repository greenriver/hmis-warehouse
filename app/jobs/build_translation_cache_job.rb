###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# warm cache from db translations
class BuildTranslationCacheJob < BaseJob
  LOCK_NAME = 'build_translation_cache'.freeze

  def perform
    Translation.with_advisory_lock(LOCK_NAME, shared: false, timeout_seconds: 0) do
      translations = Translation.order(:id).pluck(:key, :text)

      translations.in_groups_of(500, false) do |batch|
        values = batch.to_h.transform_keys { |key| Translation.cache_key(key) }
        Rails.cache.write_multi(values)
      end
    end
  end

  def max_attempts
    1
  end
end
