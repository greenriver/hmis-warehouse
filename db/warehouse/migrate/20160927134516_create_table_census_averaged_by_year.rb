class CreateTableCensusAveragedByYear < ActiveRecord::Migration
  def change
    create_table :censuses_averaged_by_year do |t|
      t.integer :year, null: false
      t.integer :data_source_id, null: false
      t.string  :OrganizationID, null: false
      t.string  :ProjectID, null: false
      t.integer :ProjectType, null: false
      t.integer :client_count, null: false, default: 0
      t.integer :bed_inventory, null: false, default: 0
      t.integer :seasonal_inventory, null: false, default: 0
      t.integer :overflow_inventory, null: false, default: 0
      t.integer :days_of_service, null: false, default: 0
    end
    add_index :censuses_averaged_by_year, [:year, :data_source_id, :ProjectType, :OrganizationID, :ProjectID], name: :index_censuses_ave_year_ds_id_proj_type_org_id_proj_id
  end
end
