class AddSchoolDistrictField < ActiveRecord::Migration[4.2]
  def change
    add_column :cohort_clients, :school_district, :string
  end
end
