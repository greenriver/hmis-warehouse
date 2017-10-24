class AddPartialReleaseConfig < ActiveRecord::Migration
  def change
    add_column :configs, :allow_partial_release, :boolean, default: true
  end
end
