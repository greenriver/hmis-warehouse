class AddUniqueConstraintToFormDefinitionIdentifier < ActiveRecord::Migration[6.1]
  def up
    safety_assured do
      add_index :hmis_form_definitions, [:identifier, :version], name: :uidx_hmis_form_definitions_identifier
      remove_index :hmis_form_definitions, name: :index_unique_identifiers_per_role
    end
  end

  def down
    safety_assured do
      remove_index :hmis_form_definitions, name: :uidx_hmis_form_definitions_identifier
      add_index :hmis_form_definitions, [:identifier, :role, :version, :status], unique: true, name: :index_unique_identifiers_per_role
    end
  end
end
