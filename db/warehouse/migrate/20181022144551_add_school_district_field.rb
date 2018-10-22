class AddSchoolDistrictField < ActiveRecord::Migration
  def change
    add_column :cohort_clients, :school_district, :string
  end
end
