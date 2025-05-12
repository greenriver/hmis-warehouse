# remove unused indexes from the csv loader and import tables
class PruneWarehouseIndexesPhase2 < ActiveRecord::Migration[7.0]
  def up
    # see 70b913b34f3
    # 6906 adjust db indexes (#4914)
    # Dba::UnusedWarehouseIndexMigrationHelper::INDEX_TEXT_OCT_2024
  end

  def down
    # could recreate indexes with a little work. However, rebuilding might require significant IOPs so this should be
    # done carefully
    raise ActiveRecord::IrreversibleMigration
  end
end
