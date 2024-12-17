class RemoveDeprecatedOverridesFromViews < ActiveRecord::Migration[7.0]
  def up
    update_analytics_views(2)
  end

  def down
    update_analytics_views(1)
  end

  protected

  def update_analytics_views(version)
    update_view 'analytics.inventories', version: version
    update_view 'analytics.projects', version: version
    update_view 'analytics.project_cocs', version: version
  end
end
