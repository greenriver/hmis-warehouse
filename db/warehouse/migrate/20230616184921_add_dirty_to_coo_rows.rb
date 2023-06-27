class AddDirtyToCooRows < ActiveRecord::Migration[6.1]
  def change
    add_column :custom_imports_b_coo_rows, :dirty, :boolean, default: false
  end
end
