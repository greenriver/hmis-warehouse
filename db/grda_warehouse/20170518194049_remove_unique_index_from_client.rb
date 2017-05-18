class RemoveUniqueIndexFromClient < ActiveRecord::Migration
  TABLES = [   # all the tables I found which had PersonalID
    GrdaWarehouse::Hud::Client,
  ]

  COLS = %w( data_source_id PersonalID )

  def down
    TABLES.each do |m|
      idxes = m.connection.indexes(m.table_name)
      existing = idxes.select{ |idx| ( idx.columns & COLS ).length == COLS.length }
      next if existing.any?
      add_index m.table_name, COLS, name: christen(m)
    end
  end

  def up
    TABLES.each do |m|
      n = christen(m)
      idxes = m.connection.indexes(m.table_name)
      next unless idxes.any?{ |idx| idx.name == n && ( idx.columns & COLS ).length == COLS.length }
      remove_index m.table_name, name: n
    end
  end

  def christen(m)
    "index_#{m.table_name}_on_#{COLS.to_sentence.gsub(/[, ]/, '_')}"
  end
end
