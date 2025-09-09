###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class CreateCasAnalyticsRejectionReasons < ActiveRecord::Migration[7.1]
  def change
    create_table :cas_analytics_rejection_reasons do |t|
      t.string :name, null: false
      t.string :referral_result
      t.timestamps
    end
  end
end
