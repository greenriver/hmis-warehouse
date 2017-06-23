class CreateNotesTable < ActiveRecord::Migration
  def change
    create_table :client_notes do |t|
      t.references :client, index: true, null: false
      t.references :user, index: true, null: false
      t.string :type, null: false
      t.text :note 
      t.timestamps     
    end
  end
end
