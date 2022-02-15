class AddBedNightsToAprClients < ActiveRecord::Migration[5.2]
  def change
    add_column :hud_report_apr_clients, :bed_nights, :integer
  end
end
