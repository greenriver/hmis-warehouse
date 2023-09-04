class AddUniqueConstraintToDefinition < ActiveRecord::Migration[6.1]
  def change
    StrongMigrations.disable_check(:add_index)
    add_index :hmis_form_definitions, [:identifier, :role, :version, :status], unique: true, name: 'index_unique_identifiers_per_role'
  ensure
    StrongMigrations.enable_check(:add_index)
  end
end
