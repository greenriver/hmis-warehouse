class AddProcessedFieldsToHmisClients < ActiveRecord::Migration
  def change
    add_column :hmis_clients, :processed_fields, :jsonb
  end
end
