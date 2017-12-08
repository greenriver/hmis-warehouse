class AddNumberOfBedroomsToVispdats < ActiveRecord::Migration
  def change
    add_column :vispdats, :number_of_bedrooms, :integer, default: 0
  end
end
