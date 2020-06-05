class CreateLftpS3Sync < ActiveRecord::Migration[5.2]
  def change
    create_table :lftp_s3_syncs do |t|
      t.references :data_source, index: true, null: false
      t.string :ftp_host, null: false
      t.string :ftp_user, null: false
      t.string :encrypted_ftp_pass, null: false
      t.string :encrypted_ftp_pass_iv, null: false
      t.string :ftp_path, null: false
      t.timestamps null: false, index: true
      t.datetime :deleted_at
    end
  end
end
