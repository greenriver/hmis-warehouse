class AddProviderSetToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :provder_set_at, :datetime
  end
end
