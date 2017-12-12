
class RebuildServiceHistoryTableWithSmallerFields < ActiveRecord::Migration
  def up
    execute <<-SQL
      CREATE TYPE record_type as ENUM ('first', 'entry', 'exit', 'service', 'extrapolated')
    SQL
    create_table :new_service_history, force: :cascade do |t|
      t.integer :client_id,                       :null=>false
      t.integer :data_source_id
      t.date    :date,                            :null=>false
      t.date    :first_date_in_program,           :null=>false
      t.date    :last_date_in_program
      t.string  :enrollment_group_id,             :limit=>50
      t.column "age", :smallint
      t.integer "destination"
      t.string  "head_of_household_id",            :limit=>50
      t.string  :household_id,                    :limit=>50
      t.string  :project_id,                      :limit=>50
      t.string  "project_name",                    :limit=>150
      t.column :project_type, :smallint
      t.integer :project_tracking_method
      t.string  :organization_id,                 :limit=>50
      t.column  :record_type, :record_type, :limit=>50, :null=>false
      t.integer "housing_status_at_entry"
      t.integer "housing_status_at_exit"
      t.column "service_type", :smallint
      t.column :computed_project_type, :smallint
      t.boolean "presented_as_individual"
      t.column "other_clients_over_25", :smallint, :default=>0, :null=>false
      t.column "other_clients_under_18", :smallint ,:default=>0, :null=>false
      t.column "other_clients_between_18_and_25", :smallint, :default=>0, :null=>false
      t.boolean "unaccompanied_youth",             :default=>false, :null=>false
      t.boolean "parenting_youth",                 :default=>false, :null=>false
      t.boolean "parenting_juvenile",              :default=>false, :null=>false
      t.boolean "children_only",                   :default=>false, :null=>false
      t.boolean "individual_adult",                :default=>false, :null=>false
      t.boolean "individual_elder",                :default=>false, :null=>false
      t.boolean "head_of_household",               :default=>false, :null=>false
    end
    add_index :new_service_history, [:client_id, :record_type], :name=>"index_sh_on_client_id", :using=>:btree
    add_index :new_service_history, [:computed_project_type, :record_type, :client_id], :name=>"index_sh_on_computed_project_type", :using=>:btree
    add_index :new_service_history, [:data_source_id, :project_id, :organization_id, :record_type], :name=>"index_sh_ds_proj_org_r_type", :using=>:btree
    add_index :new_service_history, [:record_type, :date, :data_source_id, :organization_id, :project_id, :project_type, :project_tracking_method], :name=>"index_sh_date_ds_org_proj_proj_type", :using=>:btree
    add_index :new_service_history, [:enrollment_group_id, :project_tracking_method], :name=>"index_sh__enrollment_id_track_meth", :using=>:btree
    add_index :new_service_history, [:date, :household_id, :record_type], :name=>"index_sh_on_household_id", :using=>:btree
    add_index :new_service_history, [:first_date_in_program, :last_date_in_program, :record_type, :date], :name=>"index_wsh_on_last_date_in_program", :using=>:btree
    add_index :new_service_history, :first_date_in_program, using: :brin
  end

  def down
    drop_table :new_service_history
    execute <<-SQL
      DROP TYPE record_type;
    SQL
  end
end
