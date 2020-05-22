class AddProcedureValidToQa < ActiveRecord::Migration[5.2]
  def change
    add_column :qualifying_activities, :procedure_valid, :boolean, default: false, null: false
  end
end
