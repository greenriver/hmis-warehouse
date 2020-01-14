class AddReceiversToClientSplitHistories < ActiveRecord::Migration[4.2]
  def change
    add_column :client_split_histories, :receive_hmis, :boolean
    add_column :client_split_histories, :receive_health, :boolean
  end
end
