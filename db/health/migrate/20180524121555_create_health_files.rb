class CreateHealthFiles < ActiveRecord::Migration
  def change
    create_table :health_files do |t|
      t.string :type, null: false, index: true
      t.string :file
      t.string :content_type
      t.binary :content
      t.references :client
      t.references :user
      t.timestamps 
      t.datetime :deleted_at
      t.string :note
      t.string :name
      t.float :size
    end
  end
end
