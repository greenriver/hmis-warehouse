class CreateTalentlmsLogins < ActiveRecord::Migration[5.2]
  def change
    create_table :talentlms_logins do |t|
      t.references :user
      t.string :login
      t.string :encrypted_password
      t.string :encrypted_password_iv
    end
  end
end
