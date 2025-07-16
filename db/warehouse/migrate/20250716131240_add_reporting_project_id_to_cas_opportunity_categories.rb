class AddReportingProjectIdToCasOpportunityCategories < ActiveRecord::Migration[7.1]
  def change
    add_column :cas_analytics_opportunity_categories, :reporting_project_id, :bigint
  end
end
