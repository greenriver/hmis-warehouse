class AddChDataToHmisDataQualityTool < ActiveRecord::Migration[6.1]
  def change
    add_column :hmis_dqt_clients, :ch_at_most_recent_entry, :boolean, default: false
    add_column :hmis_dqt_clients, :ch_at_any_entry, :boolean, default: false
    add_column :hmis_dqt_enrollments, :ch_at_entry, :boolean, default: false
  end
end
