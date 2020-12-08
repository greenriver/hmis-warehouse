class AddReportConfig < ActiveRecord::Migration[5.2]
  def change
    add_column :configs, :completeness_goal, :integer, default: 90
    add_column :configs, :excess_goal, :integer, default: 105
    add_column :configs, :timeliness_goal, :integer, default: 14
    add_column :configs, :income_increase_goal, :integer, default: 75
    add_column :configs, :ph_destination_increase_goal, :integer, default: 60
    add_column :configs, :move_in_date_threshold, :integer, default: 30
  end
end
