class CreateMontlyPartitionedTables < ActiveRecord::Migration[5.2]
   def up
    if GrdaWarehouseBase.connection.table_exists? Reporting::MonthlyReports::Base.parent_table
      drop_table Reporting::MonthlyReports::Base.parent_table, force: :cascade
    end

    create_table Reporting::MonthlyReports::Base.parent_table do |t|
      t.integer "month", null: false
      t.integer "year", null: false
      t.string "type"
      t.integer "client_id", null: false
      t.integer "head_of_household", default: 0, null: false
      t.string "household_id"
      t.integer "project_id", null: false
      t.integer "organization_id", null: false
      t.integer "destination_id"
      t.boolean "first_enrollment", default: false, null: false
      t.boolean "enrolled", default: false, null: false
      t.boolean "active", default: false, null: false
      t.boolean "entered", default: false, null: false
      t.boolean "exited", default: false, null: false
      t.integer "project_type", null: false
      t.date "entry_date"
      t.date "exit_date"
      t.integer "days_since_last_exit"
      t.integer "prior_exit_project_type"
      t.integer "prior_exit_destination_id"
      t.datetime "calculated_at", null: false
      t.integer "enrollment_id"
      t.date "mid_month"
    end

    Reporting::MonthlyReports::Base.sub_tables.each do |name, details|
      table_name = details[:table_name]
      constraint = "type = '#{details[:type]}'"
      sql = "CREATE TABLE #{table_name} ( CHECK ( #{constraint} ) ) INHERITS (#{Reporting::MonthlyReports::Base.parent_table});"
      execute(sql)

      add_index table_name, :id, unique: true, name: "index_month_#{name}_id"
      add_index table_name, :client_id, name: "index_month_#{name}_client_id"
      add_index table_name, [:mid_month, :destination_id, :enrolled], name: "index_month_#{name}_dest_enr"
      add_index table_name, [:mid_month, :active, :entered], name: "index_month_#{name}_act_enter"
      add_index table_name, [:mid_month, :active, :exited], name: "index_month_#{name}_act_exit"
      add_index table_name, [:mid_month, :project_type, :head_of_household], name: "index_month_#{name}_p_type_hoh"
    end
    # Don't forget the remainder
    table_name = Reporting::MonthlyReports::Base.remainder_table
    name = 'remainder'
    known = Reporting::MonthlyReports::Base.sub_tables.keys.join("', '")
    remainder_check = " type NOT IN ('#{known}') "
    sql = "CREATE TABLE #{table_name} (CHECK ( #{remainder_check} ) ) INHERITS (#{Reporting::MonthlyReports::Base.parent_table});"
    execute(sql)
    add_index table_name, :id, unique: true, name: "index_month_#{name}_id"
    add_index table_name, :client_id, name: "index_month_#{name}_client_id"
    add_index table_name, [:mid_month, :destination_id, :enrolled], name: "index_month_#{name}_dest_enr"
    add_index table_name, [:mid_month, :active, :entered], name: "index_month_#{name}_act_enter"
    add_index table_name, [:mid_month, :active, :exited], name: "index_month_#{name}_act_exit"
    add_index table_name, [:mid_month, :project_type, :head_of_household], name: "index_month_#{name}_p_type_hoh"

    trigger_ifs = []
    Reporting::MonthlyReports::Base.sub_tables.each do |name, details|
      table_name = details[:table_name]
      type = details[:type]

      constraint = "NEW.type = '#{type}'"
      trigger_ifs << " ( #{constraint} ) THEN
            INSERT INTO #{table_name} VALUES (NEW.*);
        "
    end

    trigger = "
      CREATE OR REPLACE FUNCTION monthly_reports_insert_trigger()
      RETURNS TRIGGER AS $$
      BEGIN
      IF "
    trigger += trigger_ifs.join(' ELSIF ');
    trigger += "
      ELSE
        INSERT INTO #{Reporting::MonthlyReports::Base.remainder_table} VALUES (NEW.*);
        END IF;
        RETURN NULL;
    END;
    $$
    LANGUAGE plpgsql;
    CREATE TRIGGER monthly_reports_insert_trigger
    BEFORE INSERT ON #{Reporting::MonthlyReports::Base.parent_table}
    FOR EACH ROW EXECUTE PROCEDURE monthly_reports_insert_trigger();
    "
    execute(trigger)
  end

  def down
    drop_table Reporting::MonthlyReports::Base.parent_table, force: :cascade
  end
end
