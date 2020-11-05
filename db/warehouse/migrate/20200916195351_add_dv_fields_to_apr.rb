class AddDvFieldsToApr < ActiveRecord::Migration[5.2]
  def change
    add_column :hud_report_apr_clients, :domestic_violence, :integer
    add_column :hud_report_apr_clients, :currently_fleeing, :integer
  end
end
