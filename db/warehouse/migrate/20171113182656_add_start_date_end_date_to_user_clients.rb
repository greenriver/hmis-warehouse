class AddStartDateEndDateToUserClients < ActiveRecord::Migration
  def change
    add_column :user_clients, :start_date, :date
    add_column :user_clients, :end_date, :date
  end
end
