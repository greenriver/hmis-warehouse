class AddParanoidDefinition < ActiveRecord::Migration[6.1]
  def change
    # Add deleted_at for acts_as_paranoid
    add_column :hmis_form_definitions, :deleted_at, :datetime
  end
end
