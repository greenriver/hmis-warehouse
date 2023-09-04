class RequireTitleOnDefinition < ActiveRecord::Migration[6.1]
  def change
    Hmis::Form::Definition.all.each do |d|
      d.title = d.identifier.humanize
      d.save!(validate: false)
    end
    add_check_constraint :hmis_form_definitions, "title IS NOT NULL", name: "hmis_form_definitions_title_null", validate: false
  end
end
