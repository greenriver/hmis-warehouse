class AddChronicDefinitionToConfig < ActiveRecord::Migration[4.2]
  def change
    add_column :configs, :chronic_definition, :string, null: false, default: :chronics
  end
end
