class AddIncomeAtEntryToPfReport < ActiveRecord::Migration[5.2]
  def change
    add_column :project_pass_fails_projects,  :income_at_entry_error_rate, :float
    add_column :project_pass_fails_projects,  :income_at_entry_error_count, :integer
    add_column :project_pass_fails_clients, :income_at_entry, :integer
  end
end
