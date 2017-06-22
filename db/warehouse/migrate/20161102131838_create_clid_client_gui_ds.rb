class CreateClidClientGuiDs < ActiveRecord::Migration
  def change
    create_table :api_client_data_source_ids do |t|
      t.string :warehouse_id, index: true
      t.string :id_in_data_source
      t.integer :site_id_in_data_source
      t.integer :data_source_id, index: true
    end
  end
end
