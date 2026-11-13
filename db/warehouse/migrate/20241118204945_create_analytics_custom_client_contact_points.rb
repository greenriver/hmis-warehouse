###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class CreateAnalyticsCustomClientContactPoints < ActiveRecord::Migration[7.0]
  def change
    create_view 'analytics.custom_client_contact_points'
  end
end
