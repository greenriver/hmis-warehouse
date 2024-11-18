class CreateAnalyticsCohortClients < ActiveRecord::Migration[7.0]
  def change
    create_view 'analytics.cohort_clients'
  end
end
