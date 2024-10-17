class AddDescriptionColumnToOverrideTable < ActiveRecord::Migration[7.0]
  def change
    add_column :import_overrides, :description, :varchar
  end
end
