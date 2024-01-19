class AddUniqueConstraintToFormDefinitionIdentifier < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      add_index :hmis_form_definitions, [:identifier, :version], name: :uidx_hmis_form_definitions_identifier
    end
  end
end
