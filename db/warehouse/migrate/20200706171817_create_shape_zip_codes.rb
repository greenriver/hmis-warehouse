class CreateShapeZipCodes < ActiveRecord::Migration[5.2]
  def change
    # On production and staging, only the superuser can add extensions, so this
    # will always fail there. We add the extension manually ahead of time.
    if Rails.env.development?
      reversible do |r|
        r.up do
          execute "CREATE EXTENSION postgis"
        end

        r.down do
          execute "DROP EXTENSION postgis"
        end
      end
    end

    create_table :shape_zip_codes do |t|
      t.string :zcta5ce10, limit: 5
      t.string :geoid10, limit: 5
      t.string :classfp10, limit: 2
      t.string :mtfcc10, limit: 5
      t.string :funcstat10, limit: 1
      t.float :aland10
      t.float :awater10
      t.string :intptlat10, limit: 11
      t.string :intptlon10, limit: 12
    end

    reversible do |r|
      r.up do
        srid = GrdaWarehouse::Shape::SpatialRefSys::DEFAULT_SRID
        execute "SELECT AddGeometryColumn('','shape_zip_codes','orig_geom','#{srid}','MULTIPOLYGON',2)"
        execute "SELECT AddGeometryColumn('','shape_zip_codes','geom','#{srid}','MULTIPOLYGON',2)"
      end
    end

    add_index :shape_zip_codes, :orig_geom, using: :gist
    add_index :shape_zip_codes, :geom, using: :gist
    add_index :shape_zip_codes, :zcta5ce10, unique: true
  end
end
