class CreateHealthEmergencyAmaRestrictionTable < ActiveRecord::Migration[5.2]
  def change
    create_table :health_emergency_ama_restrictions do |t|
      t.integer :user_id, null: false, index: true
      t.integer :client_id, null: false, index: true
      t.integer :agency_id, null: false, index: true
      t.string :restricted
      t.string :note

      t.timestamps null: false, index: true
      t.datetime :deleted_at
    end
  end
end
