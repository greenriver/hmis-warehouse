class AddIndexesToImports < ActiveRecord::Migration
  def change
    add_index :import_logs, :created_at
    add_index :import_logs, :updated_at
    add_index :import_logs, :completed_at
    add_index :import_logs, :data_source_id
  end
end
