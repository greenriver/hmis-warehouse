class CreateHousingStatuses < ActiveRecord::Migration[6.1]
  def change
    create_table :housing_statuses do |t|
      t.references :patient
      t.date :collected_on
      t.string :status
      t.timestamps
    end
  end
end
