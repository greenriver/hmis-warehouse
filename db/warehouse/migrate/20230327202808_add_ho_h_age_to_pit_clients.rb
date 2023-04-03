class AddHoHAgeToPitClients < ActiveRecord::Migration[6.1]
  def change
    add_column :hud_report_pit_clients, :hoh_age, :integer
  end
end
