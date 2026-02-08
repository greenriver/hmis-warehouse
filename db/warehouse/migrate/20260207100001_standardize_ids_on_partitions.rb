###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class StandardizeIdsOnPartitions< ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def up
    return unless Rails.env.development? || Rails.env.test?
    ['clients', 'enrollments', 'exits', 'services'].each do |table|
      standardize_partitioned_table(
        table: "hmis_2022_#{table}",
        columns: %i[data_source_id importer_log_id source_id]
      )
    end
  end

  def standardize_partitioned_table(table:, columns:)
    safety_assured do
      execute "DROP TABLE IF EXISTS #{table}_saved CASCADE"

      # 1. Check if the table exists and is partitioned
      result = execute("SELECT relkind FROM pg_class WHERE relname = '#{table}'").first
      return unless result && result['relkind'] == 'p'

      # 2. Rename existing partitioned table to avoid collisions
      old_table = "#{table}_old_partitioned"
      execute "DROP TABLE IF EXISTS #{old_table} CASCADE"
      execute "ALTER TABLE #{table} RENAME TO #{old_table}"

      # 3. Create a flat table with the same name and structure
      execute "CREATE TABLE #{table} (LIKE #{old_table} INCLUDING ALL)"

      # 4. Alter the columns to bigint on the flat table
      columns.each do |col|
        execute "ALTER TABLE #{table} ALTER COLUMN #{col} TYPE bigint"
      end

      # 5. Move data from the old partitioned table to the new flat table
      execute "INSERT INTO #{table} SELECT * FROM #{old_table}"

      # 6. Use PartitionMaker to recreate the partitioned structure
      pm = Dba::PartitionMaker.new(table_name: table)
      pm.run!

      # 7. Cleanup the temporary tables
      execute "DROP TABLE #{old_table} CASCADE"
      execute "DROP TABLE IF EXISTS #{table}_saved CASCADE"
    end
  end
end
