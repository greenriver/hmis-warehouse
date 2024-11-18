class CreateAnalyticsClients < ActiveRecord::Migration[7.0]
  def change
    create_view "analytics.clients"
  end
end
