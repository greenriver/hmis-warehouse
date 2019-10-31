class CreateSoapConfigs < ActiveRecord::Migration[4.2]
  def change
    create_table :soap_configs do |t|
      t.string :name
      t.string :user
      t.string :encrypted_pass
      t.string :encrypted_pass_iv
      t.string :sender
      t.string :receiver
      t.string :test_url
      t.string :production_url
    end
  end
end
