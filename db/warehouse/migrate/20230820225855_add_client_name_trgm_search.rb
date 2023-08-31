class AddClientNameTrgmSearch < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def up
    safety_assured do
      add_trgrm_extension
      add_client_name_col
      add_client_custom_name_col
    end
  end

  def down
    safety_assured do
      remove_column :Client, :search_name_fml
      remove_column :CustomClientName, :search_name_fml
    end
  end

  def add_trgrm_extension
    execute <<~SQL
      CREATE EXTENSION IF NOT EXISTS pg_trgm
    SQL
  end

  def add_client_name_col
    execute <<~SQL
      ALTER TABLE "Client"
      ADD COLUMN search_name_fml CHARACTER VARYING
      GENERATED ALWAYS AS (coalesce("FirstName", '') || ' ' || coalesce("MiddleName", '') || ' ' || coalesce("LastName", ''))
      STORED
    SQL
    # execute <<~SQL
    #   ALTER TABLE "Client"
    #   ADD COLUMN search_name_fml_metaphone CHARACTER VARYING
    #   GENERATED ALWAYS AS (dmetaphone(search_name_fml))
    #   STORED
    # SQL
    execute <<~SQL
      CREATE INDEX CONCURRENTLY client_names_gin_trgrm_idx
      ON "Client"
      USING gin (search_name_fml gin_trgm_ops);
    SQL
  end

  def add_client_custom_name_col
    execute <<~SQL
      ALTER TABLE "CustomClientName"
      ADD COLUMN search_name_fml CHARACTER VARYING
      GENERATED ALWAYS AS (coalesce("first", '') || ' ' || coalesce("middle", '') || ' ' || coalesce("last", ''))
      STORED
    SQL
    execute <<~SQL
      CREATE INDEX CONCURRENTLY client_custom_names_gin_trgrm_idx
      ON "CustomClientName"
      USING gin (search_name_fml gin_trgm_ops);
    SQL
  end

end
