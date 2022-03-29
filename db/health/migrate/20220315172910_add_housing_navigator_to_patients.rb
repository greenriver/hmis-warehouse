class AddHousingNavigatorToPatients < ActiveRecord::Migration[6.1]
  def change
    add_reference :patients, :housing_navigator
  end
end
