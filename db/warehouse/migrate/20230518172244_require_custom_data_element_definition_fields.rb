class RequireCustomDataElementDefinitionFields < ActiveRecord::Migration[6.1]
  def change
    Hmis::Hud::CustomDataElementDefinition.where(field_type: nil).delete_all
    Hmis::Hud::CustomDataElementDefinition.where(key: nil).delete_all
    Hmis::Hud::CustomDataElementDefinition.where(label: nil).delete_all

    change_column_null :CustomDataElementDefinitions, :field_type, false
    change_column_null :CustomDataElementDefinitions, :key, false
    change_column_null :CustomDataElementDefinitions, :label, false
  end
end
