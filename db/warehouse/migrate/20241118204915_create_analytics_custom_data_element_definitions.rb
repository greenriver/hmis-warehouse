class CreateAnalyticsCustomDataElementDefinitions < ActiveRecord::Migration[7.0]
  def change
    create_view "analytics.custom_data_element_definitions"
  end
end
