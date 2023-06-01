class RemovePreferredName < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!
  def change
    safety_assured { remove_column :Client, :preferred_name, :string }
  end
end
