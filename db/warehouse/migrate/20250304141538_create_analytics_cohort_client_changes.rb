class CreateAnalyticsCohortClientChanges < ActiveRecord::Migration[7.0]
  def change
    create_view 'analytics.cohort_client_changes'
  end
end
