###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class ClientDashboardCohortSetting < ActiveRecord::Migration[7.0]
  def change
    add_column :cohorts, :expose_inactive_on_client_dashboard, :boolean, default: false
  end
end
