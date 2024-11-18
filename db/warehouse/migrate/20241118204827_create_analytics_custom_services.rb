class CreateAnalyticsCustomServices < ActiveRecord::Migration[7.0]
  def change
    create_view "analytics.custom_services"
  end
end
