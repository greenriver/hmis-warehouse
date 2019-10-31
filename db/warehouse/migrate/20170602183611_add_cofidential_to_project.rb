class AddCofidentialToProject < ActiveRecord::Migration[4.2]
  def change
    add_column :Project, :confidential, :boolean, null: false, default: false
  end
end
