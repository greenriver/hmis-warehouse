class AddIndexesToHmisForms < ActiveRecord::Migration[4.2]
  def change
    add_index :hmis_forms, :name
    add_index :hmis_forms, :collected_at
  end
end
