class AddDocumentExports < ActiveRecord::Migration[5.2]
  def change
    create_table :document_exports do |t|
      t.timestamps
      t.string :type, null: false, index: true
      t.references :user, null: false, index: true
      t.string :version, null: false
      t.string :status, null: false
      t.string :query_string
      t.binary :file_data
      t.string :filename
      t.string :mime_type
    end
  end
end
