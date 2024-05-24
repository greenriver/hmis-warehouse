class AddFormUniquenessConstraints < ActiveRecord::Migration[7.0]
  def up
    safety_assured do
      remove_index :hmis_form_definitions, name: :uidx_hmis_form_definitions_identifier
      add_index :hmis_form_definitions, [:identifier, :version], unique: true, where: 'deleted_at IS NULL', name: :uidx_hmis_form_definitions_identifier
      add_index :hmis_form_definitions, [:identifier], unique: true, where: "status = 'draft' AND deleted_at IS NULL", name: :uidx_hmis_form_definitions_one_draft_per_identifier
      add_index :hmis_form_definitions, [:identifier], unique: true, where: "status = 'published' AND deleted_at IS NULL", name: :uidx_hmis_form_definitions_one_published_per_identifier
    end
  end

  def down
    safety_assured do
      remove_index :hmis_form_definitions, name: :uidx_hmis_form_definitions_identifier
      add_index :hmis_form_definitions, [:identifier, :version], name: :uidx_hmis_form_definitions_identifier
      remove_index :hmis_form_definitions, name: :uidx_hmis_form_definitions_one_draft_per_identifier
      remove_index :hmis_form_definitions, name: :uidx_hmis_form_definitions_one_published_per_identifier
    end
  end
end
