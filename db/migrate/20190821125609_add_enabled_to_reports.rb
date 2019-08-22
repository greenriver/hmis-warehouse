class AddEnabledToReports < ActiveRecord::Migration
  def change
    add_column :reports, :enabled, :boolean, default: true, null: false
  end
end
