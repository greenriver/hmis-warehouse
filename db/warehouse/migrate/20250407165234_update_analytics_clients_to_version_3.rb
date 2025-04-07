###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https: //github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class UpdateAnalyticsClientsToVersion3 < ActiveRecord::Migration[7.0]
  def change
    update_view 'analytics.clients', version: 3, revert_to_version: 2
  end
end
