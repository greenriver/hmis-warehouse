class UpdateAnalyticsClientsToVersion3 < ActiveRecord::Migration[7.0]
  def change
    update_view "analytics.clients", version: 3, revert_to_version: 2
  end
end
