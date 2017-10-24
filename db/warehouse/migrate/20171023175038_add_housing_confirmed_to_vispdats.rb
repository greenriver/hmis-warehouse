class AddHousingConfirmedToVispdats < ActiveRecord::Migration
  def change
    add_column :vispdats, :housing_release_confirmed, :boolean, default: false
  end
end
