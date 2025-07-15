###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
# frozen_string_literal: true

require 'memery'

module Hmis::AuthPolicies::ContextLoaders
  class CeReferralProjectLoader
    include Memery

    def initialize(user)
      @user = user
    end

    memoize def referral_project_ids
      o_t = Hmis::Ce::Opportunity.arel_table
      Hmis::Ce::Referral.
        joins(:opportunity).
        pluck(:id, o_t[:project_id]).
        to_h
    end
  end
end
