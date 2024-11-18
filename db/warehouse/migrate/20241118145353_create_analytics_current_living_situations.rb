class CreateAnalyticsCurrentLivingSituations < ActiveRecord::Migration[7.0]
  def change
    create_view 'analytics.current_living_situations'
  end
end
