class CreateAnalyticsInventories < ActiveRecord::Migration[7.0]
  def change
    create_view 'analytics.inventories'
  end
end
