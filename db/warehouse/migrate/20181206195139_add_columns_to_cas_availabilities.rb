class AddColumnsToCasAvailabilities < ActiveRecord::Migration[4.2]
  def change
    add_column :cas_availabilities, :part_of_a_family, :boolean, default: false, null: false
    add_column :cas_availabilities, :age_at_available_at, :integer
  end
end
