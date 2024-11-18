class CreateAnalyticsProjects < ActiveRecord::Migration[7.0]
  def change
    create_view 'analytics.projects'
  end
end
