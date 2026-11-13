# frozen_string_literal: true

class DropPgheroTables < ActiveRecord::Migration[7.2]
  def up
    drop_table :pghero_query_stats, if_exists: true
    drop_table :pghero_space_stats, if_exists: true
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
