class AddOriginalHouseholdId < ActiveRecord::Migration[5.2]
  def change
    add_column :Enrollment, :original_household_id, :string
  end
end
