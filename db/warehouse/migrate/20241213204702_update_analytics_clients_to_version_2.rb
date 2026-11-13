###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class UpdateAnalyticsClientsToVersion2 < ActiveRecord::Migration[7.0]
  def change
    update_view 'analytics.clients', version: 2, revert_to_version: 1
  end
end
