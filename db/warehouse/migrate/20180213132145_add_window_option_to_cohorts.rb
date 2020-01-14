class AddWindowOptionToCohorts < ActiveRecord::Migration[4.2]
  def change
    add_column :cohorts, :only_window, :boolean, default: false, null: false
  end
end
