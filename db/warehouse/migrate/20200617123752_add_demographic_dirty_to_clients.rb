class AddDemographicDirtyToClients < ActiveRecord::Migration[5.2]
  def change
    add_column :Client, :demographic_dirty, :boolean, default: true, index: true
  end
end
