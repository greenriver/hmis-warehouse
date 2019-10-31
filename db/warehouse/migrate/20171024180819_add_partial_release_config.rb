class AddPartialReleaseConfig < ActiveRecord::Migration[4.2]
  def change
    add_column :configs, :allow_partial_release, :boolean, default: true
  end
end
