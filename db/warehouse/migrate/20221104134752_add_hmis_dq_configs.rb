class AddHmisDqConfigs < ActiveRecord::Migration[6.1]
  def change
    add_column :hmis_dqt_goals, :entry_date_entered_length, :integer, default: 6
    add_column :hmis_dqt_goals, :exit_date_entered_length, :integer, default: 6
    add_column :hmis_dqt_goals, :expose_ch_calculations, :boolean, default: true, null: false
  end
end
