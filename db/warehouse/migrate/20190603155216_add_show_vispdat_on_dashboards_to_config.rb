class AddShowVispdatOnDashboardsToConfig < ActiveRecord::Migration
  def change
    add_column :configs, :show_vispdats_on_dashboards, :boolean, default: false
  end
end
