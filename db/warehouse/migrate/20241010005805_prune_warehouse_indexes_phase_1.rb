# remove unused indexes from the csv loader and import tables
class PruneWarehouseIndexesPhase1 < ActiveRecord::Migration[7.0]
  def up
    Dba::UnusedWarehouseIndexMigrationHelper::INDEX_TEXT_OCT_2024.split("\n").each do |definition|
      table, index_name, columns = parse_definition(definition)
      remove_index_safely(table: table, index_name: index_name, columns: columns)
    end
  end

  def down
    # could recreate indexes with a little work. However, rebuilding might require significant IOPs so this should be
    # done carefully
    raise ActiveRecord::IrreversibleMigration
  end

  protected

  def check_unused_index_table(index_name, table_name)
    sql = <<~SQL
      SELECT t.relname,
             idx.relname AS index_name,
             coalesce(idx_stat.idx_scan, 0) AS scan_count
      FROM pg_index i
      JOIN pg_class t ON t.oid = i.indrelid
      JOIN pg_class idx ON idx.oid = i.indexrelid
      LEFT JOIN pg_stat_user_indexes idx_stat
             ON idx.oid = idx_stat.indexrelid
      WHERE idx.relname = $1
    SQL

    result = GrdaWarehouseBase.connection.exec_query(sql, 'SQL', [index_name]).first

    raise "expected index #{index_name} to be on #{table_name} but was #{result['relname']}" unless result && result['relname'] == table_name

    return true if result['scan_count'].to_i.zero?

    Sentry.capture_message("Index #{index_name} on #{table_name} is in use (scan count > 0).")
    false
  end

  # it seems that the index names aren't consistent between prod and dev. Attempt to remove the index by name only
  def remove_index_safely(table:, index_name:, columns:)
    if index_exists?(table, columns, name: index_name)
      remove_index(table, name: index_name) if check_unused_index_table(index_name, table) # additional safety check
    # we could try and remove equivalent index but there's less certainty that is is unused if the name doesn't match
    # elsif Rails.env.development? && index_exists?(table, columns)
    #   remove_index(table, column: columns)
    else
      msg = "Index not found for table: #{table}, columns: #{columns.join(', ')}"
      Rails.logger.error(msg)
    end
  end

  ## dry-run
  # def remove_index(table, columns: nil, name: nil)
  #   puts "would remove: #{table}, columns: #{columns.inspect}, name: #{name}"
  # end

  def parse_definition(definition)
    # Parse the CREATE INDEX statement
    match = definition.match(/CREATE INDEX "?(?<index_name>[^"\s]+)"? ON (?:public\.)?(?<table>[^\s]+).*\((?<columns>.*)\)/)

    raise "Failed to parse index definition: #{definition}" unless match

    table = match[:table].gsub('"', '')
    index_name = match[:index_name]
    columns = match[:columns].split(',').map { |col| col.strip.gsub('"', '') }

    [table, index_name, columns]
  end
end