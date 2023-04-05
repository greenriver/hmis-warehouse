class AddCredentialsToUser < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :credentials, :string
  end
end
