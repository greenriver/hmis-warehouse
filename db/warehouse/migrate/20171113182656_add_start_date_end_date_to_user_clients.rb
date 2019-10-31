class AddStartDateEndDateToUserClients < ActiveRecord::Migration[4.2]
  def change
    add_column :user_clients, :start_date, :date
    add_column :user_clients, :end_date, :date
  end
end
