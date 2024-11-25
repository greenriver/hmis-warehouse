class CreateAnalyticsCustomServiceCategories < ActiveRecord::Migration[7.0]
  def change
    create_view 'analytics.custom_service_categories'
  end
end
