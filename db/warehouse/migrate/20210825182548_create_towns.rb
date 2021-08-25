class CreateTowns < ActiveRecord::Migration[5.2]
  def change
    create_table :shape_towns do |t|
      t.integer :fy
      t.integer :town_id
      t.string :town
      t.numeric :shape_area
      t.numeric :shape_len
      t.string :full_geoid
      t.string :geoid
    end

    reversible do |r|
      r.up do
        srid = GrdaWarehouse::Shape::SpatialRefSys::DEFAULT_SRID
        execute "SELECT AddGeometryColumn('','shape_towns','simplified_geom','#{srid}','MULTIPOLYGON',2)"
        execute "SELECT AddGeometryColumn('','shape_towns','geom','#{srid}','MULTIPOLYGON',2)"
      end
    end

    add_index :shape_towns, :simplified_geom, using: :gist
    add_index :shape_towns, :geom, using: :gist

    add_index :shape_towns, :geoid, unique: true
    add_index :shape_towns, :full_geoid
  end
end
