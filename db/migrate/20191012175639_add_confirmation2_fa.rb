class AddConfirmation2Fa < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :confirmed_2fa, :integer, default: 0, null: false
  end
end
