class AddDmhVaHuesHivHousingFlagsToClients < ActiveRecord::Migration
  def up
    add_column :Client, :dmh_eligible, :boolean, default: false, null: false, index: true
    add_column :Client, :va_eligible, :boolean, default: false, null: false, index: true
    add_column :Client, :hues_eligible, :boolean, default: false, null: false, index: true
    add_column :Client, :hiv_positive, :boolean, default: false, null: false, index: true
    add_column :Client, :housing_release_status, :string, index: true
  end

  def down
    remove_column :Client, :dmh_eligible, :boolean, default: false, null: false, index: true
    remove_column :Client, :va_eligible, :boolean, default: false, null: false, index: true
    remove_column :Client, :hues_eligible, :boolean, default: false, null: false, index: true
    remove_column :Client, :hiv_positive, :boolean, default: false, null: false, index: true
    remove_column :Client, :housing_release_status, :string, index: true
  end
end
