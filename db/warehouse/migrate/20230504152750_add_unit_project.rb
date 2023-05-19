class AddUnitProject < ActiveRecord::Migration[6.1]
  def change
    Hmis::Unit.delete_all
    add_column :hmis_units, :project_id, :integer, null: false, index: true
  end
end
