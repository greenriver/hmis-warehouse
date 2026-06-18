###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class CreateAnalyticsCurrentLivingSituations < ActiveRecord::Migration[7.0]
  def change
    create_view 'analytics.current_living_situations'
  end
end
