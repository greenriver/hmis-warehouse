class AddParentingJuvinileToAprClient < ActiveRecord::Migration[5.2]
  def change
    add_column :hud_report_apr_clients, :parenting_juvenile, :boolean
  end
end
