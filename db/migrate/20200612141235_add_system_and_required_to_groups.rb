class AddSystemAndRequiredToGroups < ActiveRecord::Migration[5.2]
  def change
    add_column :access_groups, :system, :boolean, default: false
    add_column :access_groups, :required, :boolean, default: false
  end
end
