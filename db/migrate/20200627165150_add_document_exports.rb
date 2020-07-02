class AddDocumentExports < ActiveRecord::Migration[5.2]
  def change
    create_table :document_exports do |t|
      t.timestamps
      t.string :type, null: false
      t.references :user, foreign_key: true, null: false
      t.string :version, null: false
      t.string :status, null: false
      t.string :params, :string
      t.string :file
    end
  end
end
