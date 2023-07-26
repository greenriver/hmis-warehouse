class AddCountsToEpicThrives < ActiveRecord::Migration[6.1]
  def change
    add_column :epic_thrives, :reporter, :string
    add_column :epic_thrives, :positive_food_security_count, :integer
    add_column :epic_thrives, :positive_housing_questions_count, :integer
  end
end
