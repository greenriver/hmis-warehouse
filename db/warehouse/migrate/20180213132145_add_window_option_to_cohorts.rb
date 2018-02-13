class AddWindowOptionToCohorts < ActiveRecord::Migration
  def change
    add_column :cohorts, :only_window, :boolean, default: false, null: false
  end
end
