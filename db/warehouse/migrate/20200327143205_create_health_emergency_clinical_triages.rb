class CreateHealthEmergencyClinicalTriages < ActiveRecord::Migration[5.2]
  def change
    create_table :health_emergency_clinical_triages do |t|
      t.integer :user_id, null: false, index: true
      t.integer :client_id, null: false, index: true
      t.integer :agency_id, null: false, index: true
      t.string :test_requested
      t.string :location

      t.timestamps null: false, index: true
      t.datetime :deleted_at
    end
  end
end
