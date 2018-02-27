class AddIndexesToHmisForms < ActiveRecord::Migration
  def change
    add_index :hmis_forms, :name
    add_index :hmis_forms, :collected_at
  end
end
