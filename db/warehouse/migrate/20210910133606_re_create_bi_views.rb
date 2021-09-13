class ReCreateBiViews < ActiveRecord::Migration[5.2]
  def up
    Bi::ViewMaintainer.new.remove_views
    Bi::ViewMaintainer.new.create_views
  end
end
