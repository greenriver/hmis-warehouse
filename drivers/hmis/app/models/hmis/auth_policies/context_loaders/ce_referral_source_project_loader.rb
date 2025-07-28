###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
# frozen_string_literal: true

module Hmis::AuthPolicies::ContextLoaders
  class CeReferralSourceProjectLoader
    def initialize
      # {referral_id => source_project_id, ...}
      @cache = {}
    end

    def get(referral_id)
      preload([referral_id]) unless @cache.key?(referral_id)
      @cache[referral_id] || raise("No source project found for referral #{referral_id}")
    end

    def cached_project_ids
      @cache.values.uniq
    end

    def preload(referral_ids)
      return if referral_ids.empty?

      new_referral_ids = referral_ids.uniq - @cache.keys
      return if new_referral_ids.empty?

      e_t = Hmis::Hud::Enrollment.arel_table
      results = Hmis::Ce::Referral.
        where(id: new_referral_ids).
        joins(:source_enrollment).
        pluck(:id, e_t[:project_pk]).
        to_h
      @cache.merge!(results)
    end
  end
end
