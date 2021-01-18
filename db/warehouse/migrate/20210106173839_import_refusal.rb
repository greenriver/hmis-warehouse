class ImportRefusal < ActiveRecord::Migration[5.2]
  def change
    add_column :data_sources, :refuse_imports_with_errors, :boolean, default: false
  end
end
