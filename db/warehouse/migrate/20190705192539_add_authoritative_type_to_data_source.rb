class AddAuthoritativeTypeToDataSource < ActiveRecord::Migration
  def change
    add_column :data_sources, :authoritative_type, :string
  end
end
