class CreateTalentlmsConfigs < ActiveRecord::Migration[5.2]
  def change
    create_table :talentlms_configs do |t|
      t.string :subdomain
      t.string :encrypted_api_key
      t.string :encrypted_api_key_iv
    end
  end
end
