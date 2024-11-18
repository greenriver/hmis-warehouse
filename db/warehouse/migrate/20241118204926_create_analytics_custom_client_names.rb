class CreateAnalyticsCustomClientNames < ActiveRecord::Migration[7.0]
  def change
    create_view 'analytics.custom_client_names'
  end
end
