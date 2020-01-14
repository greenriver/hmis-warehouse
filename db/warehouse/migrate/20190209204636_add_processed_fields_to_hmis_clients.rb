class AddProcessedFieldsToHmisClients < ActiveRecord::Migration[4.2]
  def change
    add_column :hmis_clients, :processed_fields, :jsonb
  end
end
