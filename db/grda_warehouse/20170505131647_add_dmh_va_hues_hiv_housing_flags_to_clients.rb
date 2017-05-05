class AddDmhVaHuesHivHousingFlagsToClients < ActiveRecord::Migration
  def up
    add_column :client, :dmh_eligible, :boolean, default: false, null: false, index: true
    add_column :client, :va_eligible, :boolean, default: false, null: false, index: true
    add_column :client, :hues_eligible, :boolean, default: false, null: false, index: true
    add_column :client, :hiv_positive, :boolean, default: false, null: false, index: true
    add_column :client, :housing_release_status, :string, index: true
  end

  def down
    remove_column :client, :dmh_eligible, :boolean, default: false, null: false, index: true
    remove_column :client, :va_eligible, :boolean, default: false, null: false, index: true
    remove_column :client, :hues_eligible, :boolean, default: false, null: false, index: true
    remove_column :client, :hiv_positive, :boolean, default: false, null: false, index: true
    remove_column :client, :housing_release_status, :string, index: true
  end
end
