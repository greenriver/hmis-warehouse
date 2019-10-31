class AddBackup2FaCodes < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :otp_backup_codes, :string, array: true
  end
end
