class AddHouseholdMoveInDateToAprClient < ActiveRecord::Migration[7.0]
  def change
    add_column :hud_report_apr_clients, :hoh_move_in_date, :date
    add_column :hud_report_apr_clients, :adjusted_move_in_date, :date
  end
end
