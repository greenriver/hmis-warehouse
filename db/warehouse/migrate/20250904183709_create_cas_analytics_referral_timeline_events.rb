###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class CreateCasAnalyticsReferralTimelineEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :cas_analytics_referral_timeline_events do |t|
      t.references :referral, index: false
      t.references :contact, index: false
      t.string :name, null: false
      t.date :event_date, null: false
      t.string :step

      t.timestamps
    end
  end
end
