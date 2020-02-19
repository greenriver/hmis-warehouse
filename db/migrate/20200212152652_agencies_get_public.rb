class AgenciesGetPublic < ActiveRecord::Migration[5.2]
  def change
    add_column :agencies, :expose_publically, :boolean, default: false, null: false
  end
end
