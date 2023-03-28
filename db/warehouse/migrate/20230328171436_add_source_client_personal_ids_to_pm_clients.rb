class AddSourceClientPersonalIdsToPmClients < ActiveRecord::Migration[6.1]
  def change
    add_column :pm_clients, :source_client_personal_ids, :string
  end
end
