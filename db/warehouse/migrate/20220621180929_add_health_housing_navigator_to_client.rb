class AddHealthHousingNavigatorToClient < ActiveRecord::Migration[6.1]
  def change
    add_reference :Client, :health_housing_navigator
  end
end
