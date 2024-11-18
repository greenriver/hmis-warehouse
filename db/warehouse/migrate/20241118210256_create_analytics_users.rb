class CreateAnalyticsUsers < ActiveRecord::Migration[7.0]
  def change
    create_view 'analytics.users'
  end
end
