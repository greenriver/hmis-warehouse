class ConvertIntegerPksToBigint < ActiveRecord::Migration[7.0]
  def up
    safety_assured {_up}
  end

  protected

  def up
    # Create the function to generate migration SQL
    execute <<-SQL
      CREATE OR REPLACE FUNCTION generate_pk_migration()
      RETURNS text AS $$
      DECLARE
          result text := '';
          r record;
      BEGIN
          -- Find all integer primary keys and their sequences
          FOR r IN (
              SELECT
                  t.table_schema,
                  t.table_name,
                  c.column_name,
                  pg_get_serial_sequence(t.table_schema || '.' || t.table_name, c.column_name) as sequence_name
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
              RAISE NOTICE 'Processing table: %', r.table_name;

              -- Drop existing primary key constraint
              result := result || format('ALTER TABLE %I.%I DROP CONSTRAINT %I_pkey; ',
                  r.table_schema, r.table_name, r.table_name);

              -- Alter column to bigint
              result := result || format('ALTER TABLE %I.%I ALTER COLUMN %I TYPE bigint; ',
                  r.table_schema, r.table_name, r.column_name);

              -- If there's an associated sequence, alter it too
              IF r.sequence_name IS NOT NULL THEN
                  result := result || format('ALTER SEQUENCE %s AS bigint; ',
                      r.sequence_name);
              END IF;

              -- Recreate primary key constraint
              result := result || format('ALTER TABLE %I.%I ADD CONSTRAINT %I_pkey PRIMARY KEY (%I); ',
                  r.table_schema, r.table_name, r.table_name, r.column_name);
          END LOOP;

          RETURN result;
      END;
      $$ LANGUAGE plpgsql;
    SQL

    # Execute the generated migration SQL
    execute "SELECT generate_pk_migration() AS migration_sql" do |result|
      execute(result.first['migration_sql']) if result.first['migration_sql'].present?
    end

    # Clean up the function
    execute "DROP FUNCTION IF EXISTS generate_pk_migration();"
  end
end
