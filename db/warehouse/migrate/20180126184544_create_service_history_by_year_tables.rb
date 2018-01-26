class CreateServiceHistoryByYearTables < ActiveRecord::Migration
  def up
    if GrdaWarehouseBase.connection.table_exists? GrdaWarehouse::ServiceHistoryService.parent_table
      drop_table GrdaWarehouse::ServiceHistoryService.parent_table, force: :cascade 
    end
    # invalidate all enrollments that think they've been processed
    GrdaWarehouse::Hud::Enrollment.update_all(processed_as: nil)
     
    create_table GrdaWarehouse::ServiceHistoryService.parent_table do |t|
      t.references :service_history_enrollment, index: false, :null=>false, foreign_key: {on_delete: :cascade}
      t.column :record_type, :record_type, :limit=>50, :null=>false
      t.date :date, null: false
      t.column "age", :smallint
      t.column "service_type", :smallint
      t.integer :client_id
      t.column "project_type", :smallint
    end
    GrdaWarehouse::ServiceHistoryService.sub_tables.each do |year, name|
      constraint = "date BETWEEN DATE '#{year}-01-01' AND DATE '#{year}-12-31'"
      sql = "CREATE TABLE #{name} ( CHECK ( #{constraint} ) ) INHERITS (#{GrdaWarehouse::ServiceHistoryService.parent_table});"
      execute(sql)
      add_index name, :id, unique: true 
      add_index name, [:date, :service_history_enrollment_id], name: "index_shs_#{year}_date_en_id" 
      add_index name, [:date, :client_id], name: "index_shs_#{year}_date_client_id"
      add_index name, [:date, :project_type], name: "index_shs_#{year}_date_project_type"
      add_index name, :date, name: "index_shs_#{year}_date_brin", :using=>:brin
    end
    name = GrdaWarehouse::ServiceHistoryService.remainder_table
    year = 1900
    remainder_check = " date < DATE '#{GrdaWarehouse::ServiceHistoryService.sub_tables.keys.min}-01-01' OR date > '#{GrdaWarehouse::ServiceHistoryService.sub_tables.keys.min}-12-31'"
    sql = "CREATE TABLE #{name} (CHECK ( #{remainder_check} ) ) INHERITS (#{GrdaWarehouse::ServiceHistoryService.parent_table});"
    execute(sql)
    add_index name, :id, unique: true 
    add_index name, [:date, :service_history_enrollment_id], name: "index_shs_#{year}_date_en_id" 
    add_index name, [:date, :client_id], name: "index_shs_#{year}_date_client_id"
    add_index name, [:date, :project_type], name: "index_shs_#{year}_date_project_type"
    add_index name, :date, name: "index_shs_#{year}_date_brin", :using=>:brin

    trigger_ifs = []
    GrdaWarehouse::ServiceHistoryService.sub_tables.each do |year, name|
      constraint = "NEW.date BETWEEN DATE '#{year}-01-01' AND DATE '#{year}-12-31'"
      trigger_ifs << " ( #{constraint} ) THEN
            INSERT INTO #{name} VALUES (NEW.*);
        "
    end

    trigger = "
      CREATE OR REPLACE FUNCTION service_history_service_insert_trigger()
      RETURNS TRIGGER AS $$
      BEGIN
      IF "
    trigger += trigger_ifs.join(' ELSIF ');
    trigger += "
      ELSE
        INSERT INTO #{GrdaWarehouse::ServiceHistoryService.remainder_table} VALUES (NEW.*);
        END IF;
        RETURN NULL;
    END;
    $$
    LANGUAGE plpgsql;
    CREATE TRIGGER service_history_service_insert_trigger
    BEFORE INSERT ON #{GrdaWarehouse::ServiceHistoryService.parent_table}
    FOR EACH ROW EXECUTE PROCEDURE service_history_service_insert_trigger();
    "
    execute(trigger)
  end

  def down
    drop_table GrdaWarehouse::ServiceHistoryService.parent_table, force: :cascade 
  end
end
