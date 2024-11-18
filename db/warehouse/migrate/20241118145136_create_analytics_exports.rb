class CreateAnalyticsExports < ActiveRecord::Migration[7.0]
  def change
    create_view "analytics.exports"
  end
end
