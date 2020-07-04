class RecreateViewsUsingModel < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!
  def up
    updater = Bi::ViewMaintainer.new
    updater.remove_views
    updater.create_views
  end

  def down
    Bi::ViewMaintainer.new.remove_views
  end
end
