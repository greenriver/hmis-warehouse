class AddAddressInfoToPlaces < ActiveRecord::Migration[6.1]
  def change
    add_column :places, :city, :string
    add_column :places, :state, :string
    add_column :places, :zipcode, :string
  end
end
