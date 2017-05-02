class CreateClientAttributes < ActiveRecord::Migration
  def change
    create_table :hmis_client_attributes_defined_text do |t|
      t.references :client, index: true
      t.references :data_source, index: true
      t.string :consent_form_status
      t.datetime :consent_form_updated_at
      t.string :source_id
      t.string :source_class
    end
  end
end
