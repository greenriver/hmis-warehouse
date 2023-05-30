class RemovePreferredName < ActiveRecord::Migration[6.1]
  def change
    safety_assured { remove_column :Client, :preferred_name }
  end
end
