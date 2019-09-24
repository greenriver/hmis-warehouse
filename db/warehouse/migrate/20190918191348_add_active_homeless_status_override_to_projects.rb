class AddActiveHomelessStatusOverrideToProjects < ActiveRecord::Migration
  def change
    add_column :Project, :active_homeless_status_override, :boolean, default: false
  end
end
