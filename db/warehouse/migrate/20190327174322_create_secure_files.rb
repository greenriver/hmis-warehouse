class CreateSecureFiles < ActiveRecord::Migration
  def change
    create_table :secure_files do |t|
      t.string :name
      t.string :file
      t.string :content_type
      t.binary :content
      t.integer :size
      t.references :sender
      t.references :recipient
      t.timestamps
      t.datetime :deleted_at
    end
  end
end
