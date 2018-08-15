class AddProjectDescriptorOverridesForLsa < ActiveRecord::Migration
  def change
    add_column :Project, :housing_type_override, :integer
    add_column :Project, :uses_move_in_date, :boolean, null: false, default: false
    add_column :Geography, :geocode_override, :string, limit: 6
    add_column :Geography, :geography_type_override, :integer
  end
end
