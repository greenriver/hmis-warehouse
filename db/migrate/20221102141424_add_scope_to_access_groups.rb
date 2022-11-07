class AddScopeToAccessGroups < ActiveRecord::Migration[6.1]
  def change
    add_column :hmis_access_groups, :scope, :string, default: :view
  end
end
