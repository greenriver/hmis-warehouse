class AddClientLastSeenConfig < ActiveRecord::Migration[5.2]
  def change
    add_column :configs, :show_client_last_seen_info_in_client_details, :boolean, default: true
  end
end
