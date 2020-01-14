class AddLockedToCareplan < ActiveRecord::Migration[4.2]
  def change
    add_column :careplans, :locked, :boolean, null: false, default: false
  end
end
