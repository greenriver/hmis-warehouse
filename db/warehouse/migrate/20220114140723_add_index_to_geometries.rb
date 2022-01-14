class AddIndexToGeometries < ActiveRecord::Migration[5.2]
  def change
    add_index :shape_counties, "((lower(namelsad)))", name: :shape_counties_namelsad_lower
    add_index :ProjectCoC, '((lower("City")))', name: :project_cocs_city_lower
    add_column :shape_zip_codes, :st_geoid, :string
    add_column :shape_zip_codes, :county_name_lower, :string
    add_index :shape_zip_codes, :st_geoid
    add_index :shape_zip_codes, :county_name_lower
  end
end
