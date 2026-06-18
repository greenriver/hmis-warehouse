###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class UpdateAnalyticsClientsToVersion3 < ActiveRecord::Migration[7.1]
  def change
    update_view 'analytics.clients', version: 3, revert_to_version: 2
  end
end
