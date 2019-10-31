class AddDmhFlagToOrganizations < ActiveRecord::Migration[4.2]
  def change
    add_column :Organization, :dmh, :boolean, default: false, null: false
  end
end
