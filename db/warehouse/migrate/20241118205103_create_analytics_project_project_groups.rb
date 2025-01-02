class CreateAnalyticsProjectProjectGroups < ActiveRecord::Migration[7.0]
  def change
    create_view 'analytics.project_project_groups'
  end
end
