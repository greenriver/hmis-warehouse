class UpdateExternalFormObjectKeyIndex < ActiveRecord::Migration[7.0]
  def change
    remove_index :hmis_form_definitions, column: :external_form_object_key
  end
end
