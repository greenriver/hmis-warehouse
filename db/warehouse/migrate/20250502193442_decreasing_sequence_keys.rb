# frozen_string_literal: true

class DecreasingSequenceKeys < ActiveRecord::Migration[7.1]
  def up
    sql = <<-SQL
      SELECT
        tbls.table_name, increment, seq.sequence_name
      FROM
        information_schema.tables AS tbls
        INNER JOIN information_schema.columns AS cols ON tbls.table_name = cols.table_name
        INNER JOIN information_schema."sequences" AS seq on seq.sequence_name = concat(tbls.table_name, '_id_seq')
      WHERE
        tbls.table_catalog = 'development_openpath_warehouse'
        AND tbls.table_schema = 'public'
        AND cols.column_name = 'id'
        AND cols.table_name NOT IN ('ClientUnencrypted', 'Site', 'bi_data_sources', 'bi_lookups_ethnicities', 'bi_lookups_funding_sources')
    SQL

    tables = GrdaWarehouseBase.connection.execute(sql)
    tables.each do |table|
      next if table['increment'] == '1'

      puts "Processing table: #{table['table_name']}"
      puts "Sequence name: #{table['sequence_name']}"

      max_id = GrdaWarehouseBase.connection.execute("SELECT MAX(id) FROM #{table['table_name']}").first['max'].to_i
      puts "Max ID: #{max_id}"
      GrdaWarehouseBase.connection.execute("ALTER SEQUENCE #{table['sequence_name']} INCREMENT BY 1")
      puts 'Sequence now increments by 1'
      GrdaWarehouseBase.connection.execute("SELECT setval('#{table['sequence_name']}', #{max_id})")
      puts "Sequence restarted at #{max_id}"
    end
  end
end
