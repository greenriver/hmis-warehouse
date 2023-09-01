class AddTitleToDefinition < ActiveRecord::Migration[6.1]
  def change
    add_column :hmis_form_definitions, :title, :string
  end
end
