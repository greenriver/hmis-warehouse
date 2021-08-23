class CreatePlaces < ActiveRecord::Migration[5.2]
  def change
    create_table :shape_places do |t|
      t.string :statefp
      t.string :placefp
      t.string :placens
      t.string :geoid
      t.string :name
      t.string :namelsad
      t.string :lsad
      t.string :classfp
      t.string :pcicbsa
      t.string :pcinecta
      t.string :mtfcc
      t.string :funcstat
      t.float :aland
      t.float :awater
      t.string :intptlat
      t.string :intptlon
    end

    reversible do |r|
      r.up do
        srid = GrdaWarehouse::Shape::SpatialRefSys::DEFAULT_SRID
        execute "SELECT AddGeometryColumn('','shape_places','simplified_geom','#{srid}','MULTIPOLYGON',2)"
        execute "SELECT AddGeometryColumn('','shape_places','geom','#{srid}','MULTIPOLYGON',2)"
      end
    end

    add_index :shape_places, :simplified_geom, using: :gist
    add_index :shape_places, :geom, using: :gist

    # add_index :shape_places, :geoid, unique: true
    # add_index :shape_places, :full_geoid
  end
end
