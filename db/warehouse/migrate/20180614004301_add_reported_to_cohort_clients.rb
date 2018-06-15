class AddReportedToCohortClients < ActiveRecord::Migration
  def change
    add_column :cohort_clients, :reported, :boolean
  end
end
