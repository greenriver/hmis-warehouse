class CreateAnalyticsLookupsProjectTypes < ActiveRecord::Migration[7.0]
  def change
    create_view 'analytics.lookups_project_types'
  end
end
