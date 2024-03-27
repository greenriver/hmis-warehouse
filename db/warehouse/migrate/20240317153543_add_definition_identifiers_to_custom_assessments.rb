class AddDefinitionIdentifiersToCustomAssessments < ActiveRecord::Migration[6.1]
  def change
    add_column :CustomAssessments, :form_definition_identifier, :string
    safety_assured do
      add_index :CustomAssessments, :form_definition_identifier
    end
  end
end
