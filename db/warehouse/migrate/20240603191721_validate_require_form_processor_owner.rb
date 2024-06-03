class ValidateRequireFormProcessorOwner < ActiveRecord::Migration[7.0]
  # rails db:migrate:up:warehouse VERSION=20240603191721
  def up
    validate_check_constraint :hmis_form_processors, name: "hmis_form_processors_owner_type_null"
    validate_check_constraint :hmis_form_processors, name: "hmis_form_processors_owner_id_null"
    change_column_null :hmis_form_processors, :owner_type, false
    change_column_null :hmis_form_processors, :owner_id, false
    remove_check_constraint :hmis_form_processors, name: "hmis_form_processors_owner_type_null"
    remove_check_constraint :hmis_form_processors, name: "hmis_form_processors_owner_id_null"
  end

  def down
    add_check_constraint :hmis_form_processors, "owner_type IS NOT NULL", name: "hmis_form_processors_owner_type_null", validate: false
    add_check_constraint :hmis_form_processors, "owner_id IS NOT NULL", name: "hmis_form_processors_owner_id_null", validate: false
    change_column_null :hmis_form_processors, :owner_type, true
    change_column_null :hmis_form_processors, :owner_id, true
  end
end
