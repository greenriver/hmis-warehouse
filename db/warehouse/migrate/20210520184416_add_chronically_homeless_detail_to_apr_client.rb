class AddChronicallyHomelessDetailToAprClient < ActiveRecord::Migration[5.2]
  def change
    add_column :hud_report_apr_clients, :chronically_homeless_detail, :string
  end
end
