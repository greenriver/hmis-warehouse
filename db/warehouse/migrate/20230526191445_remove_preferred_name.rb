class RemovePreferredName < ActiveRecord::Migration[6.1]
  def change
    disable_ddl_transaction!
    safety_assured { remove_column :Client, :preferred_name }
  end
end
