class RequireFormProcessorOwner < ActiveRecord::Migration[7.0]
  # rails db:migrate:up:warehouse VERSION=20240603191431
  # rails db:migrate:down:warehouse VERSION=20240603191431
  def change
    add_check_constraint :hmis_form_processors, "owner_type IS NOT NULL", name: "hmis_form_processors_owner_type_null", validate: false
    add_check_constraint :hmis_form_processors, "owner_id IS NOT NULL", name: "hmis_form_processors_owner_id_null", validate: false
  end
end
