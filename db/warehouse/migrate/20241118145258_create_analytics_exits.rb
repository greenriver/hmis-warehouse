class CreateAnalyticsExits < ActiveRecord::Migration[7.0]
  def change
    create_view "analytics.exits"
  end
end
