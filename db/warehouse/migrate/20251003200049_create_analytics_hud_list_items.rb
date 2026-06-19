###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class CreateAnalyticsHudListItems < ActiveRecord::Migration[7.1]
  def change
    create_view 'analytics.hud_list_items'
  end
end
