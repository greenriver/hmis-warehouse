class AddAgeAtEntryToHouseholdContexts < ActiveRecord::Migration[7.2]
  def change
    add_column :hud_report_household_contexts, :age_at_entry, :integer
    add_column :hud_report_household_contexts, :hoh_age_at_entry, :integer
  end
end
