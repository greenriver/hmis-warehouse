class AddPriorityToApiClientTable < ActiveRecord::Migration[4.2]
  def change
    add_column :api_client_data_source_ids, :temporary_high_priority, :boolean, default: false, null: false
  end
end
