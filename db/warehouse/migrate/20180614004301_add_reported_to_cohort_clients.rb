class AddReportedToCohortClients < ActiveRecord::Migration[4.2]
  def change
    add_column :cohort_clients, :reported, :boolean
  end
end
