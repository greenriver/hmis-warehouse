class AddHousingConfirmedToVispdats < ActiveRecord::Migration[4.2]
  def change
    add_column :vispdats, :housing_release_confirmed, :boolean, default: false
  end
end
