class RemoveDeletedDefinitionTypes < ActiveRecord::Migration[6.1]
  def change
    valid_roles = Hmis::Form::Definition::FORM_ROLES
    Hmis::Form::Definition.where.not(role: valid_roles).destroy_all
  end
end
