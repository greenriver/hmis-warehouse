class CreateAnalyticsDataSources < ActiveRecord::Migration[7.0]
  def change
    create_view "analytics.data_sources"
  end
end
