class RemoveUniqueIndexFromClient < ActiveRecord::Migration
  TABLES = [   # all the tables I found which had PersonalID
    GrdaWarehouse::Hud::Client,
  ]
  def up
    TABLES.each do |m|
      idxes = m.connection.indexes(m.table_name)
      existing = idxes.select{ |idx| idx.name == 'unk_Client' }
      if existing.any?
        remove_index m.table_name, name: 'unk_Client'
      end
    end
  end

end
