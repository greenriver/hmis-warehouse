class AddShowVispdatOnDashboardsToConfig < ActiveRecord::Migration[4.2]
  def change
    add_column :configs, :show_vispdats_on_dashboards, :boolean, default: false
  end
end
