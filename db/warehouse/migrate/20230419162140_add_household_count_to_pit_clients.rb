class AddHouseholdCountToPitClients < ActiveRecord::Migration[6.1]
  def change
    add_column :hud_report_pit_clients, :household_member_count, :integer
  end
end
