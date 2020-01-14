class AddActiveHomelessStatusOverrideToProjects < ActiveRecord::Migration[4.2]
  def change
    add_column :Project, :active_homeless_status_override, :boolean, default: false
  end
end
