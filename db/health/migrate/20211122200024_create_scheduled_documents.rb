class CreateScheduledDocuments < ActiveRecord::Migration[5.2]
  def change
    create_table :scheduled_documents do |t|
      t.string :type
      t.string :name

      t.string :protocol
      t.string :hostname
      t.string :port
      t.string :username
      t.string :encrypted_password
      t.string :encrypted_password_iv
      t.string :file_path

      t.datetime :last_run_at

      t.timestamps
    end
  end
end
