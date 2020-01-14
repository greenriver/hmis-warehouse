class AddDisabilityIndexes < ActiveRecord::Migration[4.2]
  def change
    add_index :Disabilities, :ProjectEntryID
    add_index :IncomeBenefits, :ProjectEntryID
    add_index :HealthAndDV, :ProjectEntryID
    add_index :EmploymentEducation, :ProjectEntryID
  end
end
