class AddCofidentialToProject < ActiveRecord::Migration
  def change
    add_column :Project, :confidential, :boolean, null: false, default: false
  end
end
