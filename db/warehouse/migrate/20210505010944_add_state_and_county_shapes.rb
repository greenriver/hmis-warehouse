class AddStateAndCountyShapes < ActiveRecord::Migration[5.2]
  def change
    create_table :shape_counties do |t|
      t.string :statefp
      t.string :countyfp
      t.string :countyns
      t.string :full_geoid
      t.string :geoid
      t.string :name
      t.string :namelsad
      t.string :lsad
      t.string :classfp
      t.string :mtfcc
      t.string :csafp
      t.string :cbsafp
      t.string :metdivfp
      t.string :funcstat
      t.float :aland
      t.float :awater
      t.string :intptlat
      t.string :intptlon
    end

    create_table :shape_states do |t|
      t.string :region
      t.string :division
      t.string :statefp
      t.string :statens
      t.string :full_geoid
      t.string :geoid
      t.string :stusps
      t.string :name
      t.string :lsad
      t.string :mtfcc
      t.string :funcstat
      t.float :aland
      t.float :awater
      t.string :intptlat
      t.string :intptlon
    end

    create_table :shape_block_groups do |t|
      t.string :statefp
      t.string :countyfp
      t.string :tractce
      t.string :blkgrpce
      t.string :geoid
      t.string :namelsad
      t.string :mtfcc
      t.string :funcstat
      t.float :aland
      t.float :awater
      t.string :intptlat
      t.string :intptlon
      t.string :full_geoid
    end

    reversible do |r|
      r.up do
        srid = GrdaWarehouse::Shape::SpatialRefSys::DEFAULT_SRID
        execute "SELECT AddGeometryColumn('','shape_counties','simplified_geom','#{srid}','MULTIPOLYGON',2)"
        execute "SELECT AddGeometryColumn('','shape_counties','geom','#{srid}','MULTIPOLYGON',2)"
        execute "SELECT AddGeometryColumn('','shape_states','simplified_geom','#{srid}','MULTIPOLYGON',2)"
        execute "SELECT AddGeometryColumn('','shape_states','geom','#{srid}','MULTIPOLYGON',2)"
        execute "SELECT AddGeometryColumn('','shape_block_groups','simplified_geom','#{srid}','MULTIPOLYGON',2)"
        execute "SELECT AddGeometryColumn('','shape_block_groups','geom','#{srid}','MULTIPOLYGON',2)"
      end
    end

    add_index :shape_counties, :simplified_geom, using: :gist
    add_index :shape_counties, :geom, using: :gist

    add_index :shape_states, :simplified_geom, using: :gist
    add_index :shape_states, :geom, using: :gist

    add_index :shape_block_groups, :simplified_geom, using: :gist
    add_index :shape_block_groups, :geom, using: :gist

    add_index :shape_counties, :statefp
    add_index :shape_counties, :geoid, unique: true
    add_index :shape_counties, :full_geoid

    add_index :shape_states, :geoid, unique: true
    add_index :shape_states, :full_geoid
    add_index :shape_states, :stusps

    add_index :shape_block_groups, :geoid, unique: true
    add_index :shape_block_groups, :full_geoid

    add_column :shape_zip_codes, :full_geoid, :string
    add_index :shape_zip_codes, :full_geoid

    add_column :shape_cocs, :full_geoid, :string
    add_index :shape_cocs, :full_geoid, unique: true

    rename_column :shape_cocs, :geom, :simplified_geom
    rename_column :shape_cocs, :orig_geom, :geom

    rename_column :shape_zip_codes, :geom, :simplified_geom
    rename_column :shape_zip_codes, :orig_geom, :geom
  end
end
