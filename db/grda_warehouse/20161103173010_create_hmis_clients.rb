class CreateHmisClients < ActiveRecord::Migration
  def change
    create_table :hmis_clients do |t|
      t.references :client
      t.text :response
      t.timestamps null: false
      t.string :consent_form_status
      t.datetime :consent_form_updated_at
    end
  end
end
