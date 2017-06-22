class CreateTableToCacheCensusData < ActiveRecord::Migration
  def change
    create_table :censuses do |t|
      t.integer :data_source_id, null: false
      t.integer :ProjectType, null: false
      t.string :OrganizationID, null: false
      t.string :ProjectID, null: false
      t.date :date, null: false
      t.boolean :veteran, null: false, default: false
      t.integer :gender, null: false, default: 99   # 99 is "data not collected" per controlled vocabulary 3.6.1
      t.integer :client_count, null: false, default: 0
      t.integer :yesterdays_count, null: false, default: 0
      t.integer :bed_inventory, null: false, default: 0
    end
    add_index :censuses, [:date]
    add_index :censuses, [:data_source_id, :ProjectType, :OrganizationID, :ProjectID], name: :index_censuses_ds_id_proj_type_org_id_proj_id
  end
end
