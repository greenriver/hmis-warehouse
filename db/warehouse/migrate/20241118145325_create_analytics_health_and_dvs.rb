class CreateAnalyticsHealthAndDvs < ActiveRecord::Migration[7.0]
  def change
    create_view "analytics.health_and_dvs"
  end
end
