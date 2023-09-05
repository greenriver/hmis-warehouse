class ValidateRequireTitleOnDefinition < ActiveRecord::Migration[6.1]
  def up
    validate_check_constraint :hmis_form_definitions, name: "hmis_form_definitions_title_null"
    change_column_null :hmis_form_definitions, :title, false
    remove_check_constraint :hmis_form_definitions, name: "hmis_form_definitions_title_null"
  end

  def down
    add_check_constraint :hmis_form_definitions, "title IS NOT NULL", name: "hmis_form_definitions_title_null", validate: false
    change_column_null :hmis_form_definitions, :title, true
  end
end