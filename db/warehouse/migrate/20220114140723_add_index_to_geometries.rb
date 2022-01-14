class AddIndexToGeometries < ActiveRecord::Migration[5.2]
  def change
    add_index :shape_counties, "((lower(namelsad)))", name: :shape_counties_namelsad_lower
    add_index :ProjectCoC, '((lower("City")))', name: :project_cocs_city_lower
  end
end
