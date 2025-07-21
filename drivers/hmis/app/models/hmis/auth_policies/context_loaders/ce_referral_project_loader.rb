###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
# frozen_string_literal: true

module Hmis::AuthPolicies::ContextLoaders
  class CeReferralProjectLoader
    def initialize
      # {referral_id => project_id, ...}
      @cache = {}
    end

    def get(referral_id)
      preload([referral_id]) unless @cache.key?(referral_id)
      @cache[referral_id] || raise("No project found for referral #{referral_id}")
    end

    def cached_project_ids
      @cache.values.uniq
    end

    def preload(referral_ids)
      return if referral_ids.empty?

      new_referral_ids = referral_ids.uniq - @cache.keys
      return if new_referral_ids.empty?

      o_t = Hmis::Ce::Opportunity.arel_table
      results = Hmis::Ce::Referral.
        where(id: new_referral_ids).
        joins(:opportunity).
        pluck(:id, o_t[:project_id]).
        to_h
      @cache.merge!(results)
    end
  end
end
