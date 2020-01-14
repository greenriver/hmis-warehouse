class AddAuthoritativeToDataSources < ActiveRecord::Migration[4.2]
  def change
    add_column :data_sources, :authoritative, :boolean, default: false, index: true
  end
end
