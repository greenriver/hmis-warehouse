class AddLockedToCareplan < ActiveRecord::Migration
  def change
    add_column :careplans, :locked, :boolean, null: false, default: false
  end
end
