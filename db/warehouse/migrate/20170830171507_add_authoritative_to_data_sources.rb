class AddAuthoritativeToDataSources < ActiveRecord::Migration
  def change
    add_column :data_sources, :authoritative, :boolean, default: false, index: true
  end
end
