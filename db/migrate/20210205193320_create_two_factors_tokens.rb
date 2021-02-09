class CreateTwoFactorsMemorizedDevices < ActiveRecord::Migration[5.2]
  def change
    create_table :two_factors_memorized_devices do |t|
      t.references :user, foreign_key: true
      t.string :uuid
      t.string :name
      t.integer :session_id
      t.ip_address :log_in_ip

      t.timestamps
    end
  end
end
