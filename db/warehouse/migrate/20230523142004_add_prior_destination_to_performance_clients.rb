class AddPriorDestinationToPerformanceClients < ActiveRecord::Migration[6.1]
  def change
    [:reporting, :comparison].each do |period|
      add_column :pm_clients, "#{period}_prior_destination", :integer
    end
  end
end
