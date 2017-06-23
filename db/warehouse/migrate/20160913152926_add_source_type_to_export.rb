class AddSourceTypeToExport < ActiveRecord::Migration
  def up
    add_column table, column, :integer
  end

  def down
    remove_column table, column
  end

  def table
    GrdaWarehouse::Hud::Export.table_name
  end

  # pedantic...
  def column
    'SourceType'
  end
end
