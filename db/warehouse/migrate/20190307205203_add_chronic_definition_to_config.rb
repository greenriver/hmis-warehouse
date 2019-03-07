class AddChronicDefinitionToConfig < ActiveRecord::Migration
  def change
    add_column :configs, :chronic_definition, :string, null: false, default: :chronic
  end
end
