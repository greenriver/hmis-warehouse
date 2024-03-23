class AddIndexes < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      add_index :medications, :patient_id
    end
  end
end
