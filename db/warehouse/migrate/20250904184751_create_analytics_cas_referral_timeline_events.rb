###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class CreateAnalyticsCasReferralTimelineEvents < ActiveRecord::Migration[7.1]
  def change
    create_view 'analytics.cas_referral_timeline_events'
  end
end
