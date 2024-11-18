class CreateAnalyticsProjectCocs < ActiveRecord::Migration[7.0]
  def change
    create_view 'analytics.project_cocs'
  end
end
