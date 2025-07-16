class AddOpportunityAvailableAtToCasOpportunities < ActiveRecord::Migration[7.1]
  def change
    add_column :cas_analytics_opportunities, :made_available_at, :datetime
  end
end
