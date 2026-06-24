###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class CreateCeDeclineReasonAnalyticsView < ActiveRecord::Migration[7.2]
  def change
    create_view 'analytics.ce_referral_decline_reasons'
  end
end
