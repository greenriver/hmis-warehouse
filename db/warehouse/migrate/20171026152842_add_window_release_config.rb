class AddWindowReleaseConfig < ActiveRecord::Migration[4.2]
  def change
    add_column :configs, :window_access_requires_release, :boolean, default: :false
  end
end
