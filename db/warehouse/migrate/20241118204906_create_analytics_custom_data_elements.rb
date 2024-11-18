class CreateAnalyticsCustomDataElements < ActiveRecord::Migration[7.0]
  def change
    create_view 'analytics.custom_data_elements'
  end
end
