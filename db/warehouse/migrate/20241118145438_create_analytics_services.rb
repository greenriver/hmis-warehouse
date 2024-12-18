class CreateAnalyticsServices < ActiveRecord::Migration[7.0]
  def change
    create_view 'analytics.services'
  end
end
