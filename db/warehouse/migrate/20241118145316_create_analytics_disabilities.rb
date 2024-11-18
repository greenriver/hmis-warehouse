class CreateAnalyticsDisabilities < ActiveRecord::Migration[7.0]
  def change
    create_view 'analytics.disabilities'
  end
end
