class AddConfigForAccountRequests < ActiveRecord::Migration[5.2]
  def change
    add_column :configs, :request_account_available, :boolean, default: false, null: false
  end
end
