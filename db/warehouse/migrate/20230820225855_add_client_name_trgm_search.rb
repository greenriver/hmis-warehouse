class AddClientNameTrgmSearch < ActiveRecord::Migration[6.1]
  # disable_ddl_transaction!

  # add normalized generated search cols
  def up
    safety_assured do
      add_extensions
      add_client_names
      add_client_custom_names
    end
  end

  def down
    safety_assured do
      remove_column :Client, :search_name_full
      remove_column :Client, :search_name_last
      remove_column :CustomClientName, :search_name_full
      remove_column :CustomClientName, :search_name_last
    end
  end

  def add_extensions
    execute <<~SQL
      CREATE EXTENSION IF NOT EXISTS pg_trgm
    SQL
    execute <<~SQL
      CREATE EXTENSION IF NOT EXISTS unaccent
    SQL

    # unaccent() is STABLE but not IMMUTABLE. The following creates an IMMUTABLE SQL wrapper for use in generated / index cols
    # reference: https://stackoverflow.com/questions/11005036/does-postgresql-support-accent-insensitive-collations/11007216#11007216
    execute <<~SQL
    CREATE OR REPLACE FUNCTION public.f_unaccent(text)
      RETURNS text
      LANGUAGE sql IMMUTABLE PARALLEL SAFE STRICT AS
    $func$
    SELECT public.unaccent('public.unaccent', $1)  -- schema-qualify function and dictionary
    $func$;
    SQL
  end

  def add_client_names
    # first-middle-last
    # notes
    # * cannot use contact_ws() since it is not immutable
    # * generated strings have additional spaces "  " but non-word chars are not significant for similarity matches
    execute <<~SQL
      ALTER TABLE "Client"
      ADD COLUMN search_name_full CHARACTER VARYING
      GENERATED ALWAYS AS (
        f_unaccent(coalesce("FirstName", '') || ' ' || coalesce("MiddleName", '') || ' ' || coalesce("LastName", ''))
      )
      STORED
    SQL
    execute <<~SQL
      CREATE INDEX idx_client_name_full_gin ON "Client" USING gin (search_name_full gin_trgm_ops)
    SQL

    # last name
    execute <<~SQL
      ALTER TABLE "Client"
      ADD COLUMN search_name_last CHARACTER VARYING
      GENERATED ALWAYS AS (f_unaccent("LastName"))
      STORED
    SQL
    execute <<~SQL
      CREATE INDEX idx_client_name_last_gin ON "Client" USING gin (search_name_last gin_trgm_ops)
    SQL
  end

  def add_client_custom_names
    execute <<~SQL
      ALTER TABLE "CustomClientName"
      ADD COLUMN search_name_full CHARACTER VARYING
      GENERATED ALWAYS AS (
        f_unaccent(coalesce("first", '') || ' ' || coalesce("middle", '') || ' ' || coalesce("last", ''))
      )
      STORED
    SQL
    execute <<~SQL
      CREATE INDEX idx_client_custom_names_full_idx ON "CustomClientName" USING gin (search_name_full gin_trgm_ops)
    SQL

    execute <<~SQL
      ALTER TABLE "CustomClientName"
      ADD COLUMN search_name_last CHARACTER VARYING
      GENERATED ALWAYS AS (f_unaccent("last"))
      STORED
    SQL
    execute <<~SQL
      CREATE INDEX idx_client_custom_names_last_idx ON "CustomClientName" USING gin (search_name_last gin_trgm_ops)
    SQL
  end

end
