class CreateTwoFactorsMemorizedDevices < ActiveRecord::Migration[5.2]
  def change
    create_table :two_factors_memorized_devices do |t|
      t.references :user, foreign_key: true, null: false
      t.string :uuid, null: false, unique: true
      t.string :name, null: false
      t.datetime :expires_at, null: false
      t.integer :session_id
      t.string :log_in_ip

      t.timestamps
    end
  end
end
