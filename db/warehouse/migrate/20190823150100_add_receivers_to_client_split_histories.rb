class AddReceiversToClientSplitHistories < ActiveRecord::Migration
  def change
    add_column :client_split_histories, :receive_hmis, :boolean
    add_column :client_split_histories, :receive_health, :boolean
  end
end
