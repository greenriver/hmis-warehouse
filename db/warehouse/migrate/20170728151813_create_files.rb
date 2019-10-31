class CreateFiles < ActiveRecord::Migration[4.2]
  def change
    create_table :files do |t|
      t.string :type, null: false, index: true
      t.string :file
      t.string :content_type
      t.binary :content
      t.references :client
      t.references :user
      t.timestamps 
      t.datetime :deleted_at
    end
  end
end
