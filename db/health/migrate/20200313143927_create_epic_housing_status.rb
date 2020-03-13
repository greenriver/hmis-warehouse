class CreateEpicHousingStatus < ActiveRecord::Migration[5.2]
  def change
    create_table :epic_housing_statuses do |t|
      t.string :patient_id, null: false, index: true
      t.date :collected_on, null: false, index: true
      t.string :status, null: false
      t.timestamps
    end
  end
end
