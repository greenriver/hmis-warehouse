class AddDmhFlagToOrganizations < ActiveRecord::Migration
  def change
    add_column :Organization, :dmh, :boolean, default: false, null: false
  end
end
