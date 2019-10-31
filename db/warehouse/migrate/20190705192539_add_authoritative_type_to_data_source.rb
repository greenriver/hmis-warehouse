class AddAuthoritativeTypeToDataSource < ActiveRecord::Migration[4.2]
  def change
    add_column :data_sources, :authoritative_type, :string
  end
end
