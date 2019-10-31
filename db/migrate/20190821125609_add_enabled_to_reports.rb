class AddEnabledToReports < ActiveRecord::Migration[4.2]
  def change
    add_column :reports, :enabled, :boolean, default: true, null: false
  end
end
