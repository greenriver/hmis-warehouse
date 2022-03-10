class AddHouseholdIdToPassFail < ActiveRecord::Migration[6.1]
  def change
    add_column :project_pass_fails_clients, :household_id, :string
    add_column :project_pass_fails_projects, :available_units, :integer
    add_column :project_pass_fails_projects, :unit_utilization_rate, :float
    add_column :project_pass_fails_projects, :unit_utilization_count, :integer
    add_column :project_pass_fails, :unit_utilization_rate, :float
  end
end
