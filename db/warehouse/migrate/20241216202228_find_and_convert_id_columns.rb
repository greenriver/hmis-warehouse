class FindAndConvertIdColumns < ActiveRecord::Migration[7.0]
  def up
    return unless runnable?

    safety_assured do
      without_views do
        without_service_history_services_materialized do
          convert_pks
          convert_pk_references
        end
      end
    end
  end

  def down
    return unless runnable?

    raise ActiveRecord::IrreversibleMigration,
      "Converting bigint primary keys back to integer is unsafe as it may cause data loss"
  end

  protected

  def runnable?
    # we handle this manually in production and staging
    Rails.env.development? || Rails.env.test?
  end

  def convert_pks
    # Create the function to generate migration SQL
    execute <<-SQL
      CREATE OR REPLACE FUNCTION generate_pk_migration()
      RETURNS text AS $$
      DECLARE
        result text := '';
        r record;
        actual_constraint_name text;
      BEGIN
        -- Find all integer primary keys and their sequences
        FOR r IN (
          SELECT
            t.table_schema,
            t.table_name,
            c.column_name,
            tc.constraint_name,
            format('%I.%I', t.table_schema, t.table_name)::regclass::text as quoted_table,
            pg_get_serial_sequence(format('%I.%I', t.table_schema, t.table_name)::regclass::text, c.column_name) as sequence_name
          FROM information_schema.tables t
          JOIN information_schema.columns c
            ON t.table_schema = c.table_schema
            AND t.table_name = c.table_name
          JOIN information_schema.table_constraints tc
            ON t.table_schema = tc.table_schema
            AND t.table_name = tc.table_name
          JOIN information_schema.key_column_usage kcu
            ON tc.constraint_schema = kcu.constraint_schema
            AND tc.constraint_name = kcu.constraint_name
            AND c.column_name = kcu.column_name
          WHERE t.table_schema NOT IN ('pg_catalog', 'information_schema')
          AND tc.constraint_type = 'PRIMARY KEY'
          AND c.data_type = 'integer'
        ) LOOP
          -- Add progress message
          RAISE NOTICE 'Processing table: % (constraint: %)', r.table_name, r.constraint_name;

          -- Drop existing primary key constraint using actual constraint name
          result := result || format('ALTER TABLE %I.%I DROP CONSTRAINT %I; ',
            r.table_schema, r.table_name, r.constraint_name);

          -- Alter column to bigint
          result := result || format('ALTER TABLE %I.%I ALTER COLUMN %I TYPE bigint; ',
            r.table_schema, r.table_name, r.column_name);

          -- If there's an associated sequence, alter it too
          IF r.sequence_name IS NOT NULL THEN
            result := result || format('ALTER SEQUENCE %s AS bigint; ',
              r.sequence_name);
          END IF;

          -- Recreate primary key constraint using original constraint name
          result := result || format('ALTER TABLE %I.%I ADD CONSTRAINT %I PRIMARY KEY (%I); ',
            r.table_schema, r.table_name, r.constraint_name, r.column_name);
        END LOOP;

        RETURN result;
      END;
      $$ LANGUAGE plpgsql;
    SQL

    # Execute the generated migration SQL
    execute "SELECT generate_pk_migration() AS migration_sql" do |result|
      if result.first['migration_sql'].present?
        puts "Generated migration SQL: #{result.first['migration_sql']}"  # Debug output
        execute(result.first['migration_sql'])
      else
        puts "No tables found requiring migration"  # Debug output
      end
    end

    # Clean up the function
    execute "DROP FUNCTION IF EXISTS generate_pk_migration();"
  end

  def convert_pk_references
    # Find all integer columns ending in _id
    columns_to_convert = execute(<<-SQL).to_a
      SELECT DISTINCT
        t.table_name,
        c.column_name
      FROM information_schema.tables t
      JOIN information_schema.columns c
        ON t.table_schema = c.table_schema
        AND t.table_name = c.table_name
      LEFT JOIN pg_catalog.pg_class pgc
        ON pgc.relname = t.table_name
      LEFT JOIN pg_catalog.pg_inherits pgi
        ON pgi.inhrelid = pgc.oid
      WHERE t.table_schema NOT IN ('pg_catalog', 'information_schema')
      AND t.table_type = 'BASE TABLE'
      AND c.data_type = 'integer'
      AND c.column_name LIKE '%\_id' ESCAPE '\'
      AND pgi.inhrelid IS NULL  -- This excludes partition tables
    SQL

    # Do the conversion
    columns_to_convert.each do |row|
      execute <<-SQL
        ALTER TABLE "#{row['table_name']}" ALTER COLUMN "#{row['column_name']}" TYPE bigint
      SQL
    end
  end

  # special handling to recreate indexes
  def without_service_history_services_materialized
    table, version = read_view_files.detect do |name, _|
      name == 'service_history_services_materialized'
    end
    raise unless table
    drop_view(table, materialized: true)
    yield
    create_view(table, version: version, materialized: true)
    add_index "service_history_services_materialized", ["client_id", "date"], name: "index_shsm_c_id_date"
    add_index "service_history_services_materialized", ["client_id", "project_type", "record_type"], name: "index_shsm_c_id_p_type_r_type"
    add_index "service_history_services_materialized", ["homeless", "project_type", "client_id"], name: "index_shsm_homeless_p_type_c_id"
    add_index "service_history_services_materialized", ["id"], name: "index_service_history_services_materialized_on_id", unique: true
    add_index "service_history_services_materialized", ["literally_homeless", "project_type", "client_id"], name: "index_shsm_literally_homeless_p_type_c_id"
    add_index "service_history_services_materialized", ["service_history_enrollment_id"], name: "index_shsm_shse_id"
  end

  def without_views
    views = read_view_files.map do |name, v|
      [name.gsub(/\Aanalytics_/, 'analytics.'), v]
    end
    views = views.filter do |name, _|
      # these are in the app db
      name !~ /(hmis_user_enrollment_activity_log_summaries|hmis_user_client_activity_log_summaries|service_history_services_materialized)/
    end
    views.each do |name, _|
      drop_view(name)
    end
    yield
    views.each do |name, version|
      create_view(name, version: version)
    end
  end

  def read_view_files
    views_dir = Rails.root.join('db', 'views')
    files = Dir.glob("#{views_dir}/*.sql")

    file_versions = files.map do |file|
      base_name = File.basename(file, '.sql')

      # Match the file name pattern (e.g., 'analytics_affiliations_v01')
      if base_name =~ /(.*)_v(\d+)$/
        name = $1
        version = $2.to_i
        [name, version]
      end
    end.compact

    # Group by the file name and find the maximum version
    file_versions.group_by(&:first).map do |name, versions|
      [name, versions.map(&:last).max]
    end
  end

end
