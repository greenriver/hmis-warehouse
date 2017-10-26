class AddWindowReleaseConfig < ActiveRecord::Migration
  def change
    add_column :configs, :window_access_requires_release, :boolean, default: :false
  end
end
