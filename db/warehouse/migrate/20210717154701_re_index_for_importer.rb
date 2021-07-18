class ReIndexForImporter < ActiveRecord::Migration[5.2]
  def up
    execute <<-SQL
      CREATE TYPE record_action as ENUM ('added', 'updated', 'unchanged', 'removed')
    SQL
    create_table :involved_in_imports do |t|
      t.references :importer_log
      t.references :record, null: false, polymorphic: true, index: false
      t.string :hud_key, null: false
      t.column  :record_action, :record_action, limit: 50
    end
    add_index :involved_in_imports, [:record_id, :importer_log_id, :record_type, :record_action], name: 'involved_in_imports_by_id', unique: true
    add_index :involved_in_imports, [:hud_key, :importer_log_id, :record_type, :record_action], name: 'involved_in_imports_by_hud_key', unique: true
    add_index :involved_in_imports, [:importer_log_id, :record_type, :record_action], name: 'involved_in_imports_by_hud_key', unique: true
  end

  def down
    drop_table :involved_in_imports
    execute <<-SQL
      DROP TYPE record_action
    SQL
  end
end
