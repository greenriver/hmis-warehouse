class AddShelterPriorityToEnrollmentExtras < ActiveRecord::Migration[6.1]
  def change
    add_column :enrollment_extras, :shelter_priority, :string
    add_column :enrollment_extras, :permanent_housing_priority_group, :string
  end
end
