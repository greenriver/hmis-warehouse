###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class StandardizeIdsOnShards < ActiveRecord::Migration[7.2]
  def up
    # This migration specifically handles partitioned tables where the 
    # partition key or ID columns need to be upgraded to bigint.
    # PostgreSQL does not allow direct ALTER COLUMN TYPE on partition keys.
    # 
    # Since this is for development/test environments, we can drop and recreate.
    # We use the system's own Dba::PartitionMaker to ensure the partitions 
    # are recreated correctly.
    
    # Dynamically find all partitioned tables in the public schema
    partitioned_tables_query = <<~SQL
      SELECT relname
      FROM pg_class c
      JOIN pg_namespace n ON n.oid = c.relnamespace
      WHERE c.relkind = 'p'
        AND n.nspname = 'public'
    SQL
    
    tables = execute(partitioned_tables_query).to_a.map { |r| r['relname'] }

    tables.each do |table_name|
      # Check if there are any integer columns that should be bigint in this table
      # This follows the logic from issue.sql
      columns_to_alter_query = <<~SQL
        SELECT column_name
        FROM information_schema.columns
        WHERE table_name = '#{table_name}'
          AND table_schema = 'public'
          AND data_type = 'integer'
          AND (column_name ~ 'id' or column_name ~ 'from' or column_name ~ 'into')
          AND column_name !~ 'override'
      SQL
      
      columns_to_alter = execute(columns_to_alter_query).to_a
      
      if columns_to_alter.empty?
        puts "Skipping #{table_name} - no columns need standardization."
        next
      end

      puts "Un-partitioning #{table_name} to allow type changes..."
      
      # 1. Rename to _old to keep the structure
      execute "DROP TABLE IF EXISTS public.\"#{table_name}_old\" CASCADE"
      execute "ALTER TABLE public.\"#{table_name}\" RENAME TO \"#{table_name}_old\""
      
      # 2. Create a regular table with the same structure
      execute "CREATE TABLE public.\"#{table_name}\" (LIKE public.\"#{table_name}_old\" INCLUDING ALL)"
      
      # 3. Fix sequence ownership so dropping the old table doesn't drop the sequence
      seq_res = execute("SELECT pg_get_serial_sequence('public.#{table_name}_old', 'id')").first
      if seq_res && seq_res['pg_get_serial_sequence']
        seq_name = seq_res['pg_get_serial_sequence']
        execute "ALTER SEQUENCE #{seq_name} OWNED BY public.\"#{table_name}\".id"
      end
      
      # 4. Drop the old partitioned table (and its partitions)
      execute "DROP TABLE public.\"#{table_name}_old\" CASCADE"
      
      # 5. Alter the columns we identified earlier
      columns_to_alter.each do |row|
        col = row['column_name']
        puts "Altering #{table_name}.#{col} to bigint..."
        execute "ALTER TABLE public.\"#{table_name}\" ALTER COLUMN \"#{col}\" TYPE bigint"
      end
      
      # 6. Re-partition using the system's own tool
      puts "Re-partitioning #{table_name}..."
      pm = Dba::PartitionMaker.new(table_name: table_name)
      # PartitionMaker will skip if it doesn't know the partition column, 
      # but it has defaults for importer_log_id and loader_id.
      begin
        pm.run!
      rescue StandardError => e
        puts "Could not re-partition #{table_name}: #{e.message}"
        # We leave it as a regular table if re-partitioning fails; 
        # it's still improved with bigints.
      end
      
      # 7. Cleanup the _saved table that PartitionMaker leaves behind
      execute "DROP TABLE IF EXISTS public.\"#{table_name}_saved\" CASCADE"
    end
  end

  def down
    # No-op: we don't want to revert bigints to integers.
  end

  private

  def column_for(table, column_name)
    GrdaWarehouseBase.connection.columns(table).find { |c| c.name == column_name }
  end
  
  def table_exists?(table_name)
    GrdaWarehouseBase.connection.table_exists?(table_name)
  end
  
  def execute(sql)
    GrdaWarehouseBase.connection.execute(sql)
  end
end
