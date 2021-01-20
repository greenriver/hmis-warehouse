class CreateHealthEmergencyImmunizations < ActiveRecord::Migration[5.2]
  def change
    create_table :health_emergency_vaccinations do |t|
      t.integer :user_id, null: false, index: true
      t.integer :client_id, null: false, index: true
      t.integer :agency_id, index: true
      t.date :vaccinated_on, null: false
      t.string :vaccinated_at
      t.date :follow_up_on
      t.datetime :follow_up_notification_sent_at
      t.string :vaccination_type, null: false
      t.string :follow_up_cell_phone
      t.string :emergency_type

      t.timestamps null: false, index: true
      t.datetime :deleted_at
    end
  end
end
