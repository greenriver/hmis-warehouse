class AddNameToYouthIntake < ActiveRecord::Migration[5.2]
  def change
    add_column :youth_intakes, :first_name, :string
    add_column :youth_intakes, :last_name, :string
    add_column :youth_intakes, :ssn, :string
  end
end
