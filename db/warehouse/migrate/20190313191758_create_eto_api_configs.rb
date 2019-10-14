class CreateEtoApiConfigs < ActiveRecord::Migration
  def change
    create_table :eto_api_configs do |t|
      t.references :data_source, null: false, index: true
      t.jsonb :touchpoint_fields
      t.jsonb :demographic_fields
      t.jsonb :demographic_fields_with_attributes
      t.jsonb :additional_fields
      t.timestamps
    end
  end
end
