class CreateShapeCocs < ActiveRecord::Migration[5.2]
  def change
    create_table :shape_cocs do |t|
      t.string :st
      t.string :state_name
      t.string :cocnum
      t.string :cocname
      t.numeric :ard
      t.numeric :pprn
      t.numeric :fprn
      t.string :fprn_statu
      t.numeric :es_c_hwac
      t.numeric :es_c_hwoa_
      t.numeric :es_c_hwoc
      t.numeric :es_vso_tot
      t.numeric :th_c_hwac_
      t.numeric :th_c_hwoa
      t.numeric :th_c_hwoc
      t.numeric :th_c_vet
      t.numeric :rrh_c_hwac
      t.numeric :rrh_c_hwoa
      t.numeric :rrh_c_hwoc
      t.numeric :rrh_c_vet
      t.numeric :psh_c_hwac
      t.numeric :psh_c_hwoa
      t.numeric :psh_c_hwoc
      t.numeric :psh_c_vet
      t.numeric :psh_c_ch
      t.string :psh_u_hwac
      t.string :psh_u_hwoa
      t.string :psh_u_hwoc
      t.string :psh_u_vet
      t.string :psh_u_ch
      t.numeric :sh_c_hwoa
      t.numeric :sh_c_vet
      t.numeric :sh_pers_hw
      t.numeric :unsh_pers_
      t.numeric :sh_pers__1
      t.numeric :unsh_pers1
      t.numeric :sh_pers__2
      t.numeric :unsh_per_1
      t.numeric :sh_ch
      t.numeric :unsh_ch
      t.numeric :sh_youth_u
      t.numeric :unsh_youth
      t.numeric :sh_vets
      t.numeric :unsh_vets
      t.numeric :shape_leng
      t.numeric :shape_area
    end

    reversible do |r|
      r.up do
        srid = GrdaWarehouse::Shape::SpatialRefSys::DEFAULT_SRID
        execute "SELECT AddGeometryColumn('','shape_cocs','orig_geom','#{srid}','MULTIPOLYGON',2)"
        execute "SELECT AddGeometryColumn('','shape_cocs','geom','#{srid}','MULTIPOLYGON',2)"
      end
    end

    add_index :shape_cocs, :orig_geom, using: :gist
    add_index :shape_cocs, :geom, using: :gist
    add_index :shape_cocs, :cocname
    add_index :shape_cocs, :st
  end
end
