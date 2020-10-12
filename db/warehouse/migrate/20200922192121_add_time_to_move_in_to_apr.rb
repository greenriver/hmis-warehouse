class AddTimeToMoveInToApr < ActiveRecord::Migration[5.2]
  def change
    add_column :hud_report_apr_clients, :time_to_move_in, :integer
    add_column :hud_report_apr_clients, :approximate_length_of_stay, :integer
    add_column :hud_report_apr_clients, :approximate_time_to_move_in, :integer
    add_column :hud_report_apr_clients, :date_to_street, :date
    add_column :hud_report_apr_clients, :housing_assessment, :integer
  end
end
