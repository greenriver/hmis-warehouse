class AddHouseholdMembersToAprClient < ActiveRecord::Migration[5.2]
  def change
    add_column :hud_report_apr_clients, :household_members, :jsonb
  end
end
