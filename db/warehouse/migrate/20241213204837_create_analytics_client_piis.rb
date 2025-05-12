class CreateAnalyticsClientPiis < ActiveRecord::Migration[7.0]
  def change
    create_view 'analytics.client_piis'
  end
end
