class AddCaseMangerToHmisClient < ActiveRecord::Migration[4.2]
  def change
    add_column :hmis_clients, :case_manager_entity_id, :integer
    add_column :hmis_clients, :case_manager_name, :string
  end
end
